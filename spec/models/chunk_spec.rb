# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chunk do
  describe "associations" do
    it { is_expected.to belong_to(:chunkable) }
    it { is_expected.to belong_to(:embedding_provider).optional }
  end

  describe "validations" do
    subject { build(:chunk) }

    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:chunk_index) }
    it { is_expected.to validate_numericality_of(:chunk_index).is_greater_than_or_equal_to(0) }

    it "validates uniqueness of chunk_index within chunkable" do
      question = create(:question)
      create(:chunk, chunkable: question, chunk_index: 0)

      duplicate = build(:chunk, chunkable: question, chunk_index: 0)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:chunk_index]).to include("must be unique within the parent document")
    end

    it "allows same chunk_index for different chunkables" do
      question1 = create(:question)
      question2 = create(:question)
      create(:chunk, chunkable: question1, chunk_index: 0)

      chunk2 = build(:chunk, chunkable: question2, chunk_index: 0)
      expect(chunk2).to be_valid
    end
  end

  describe "scopes" do
    describe ".ordered" do
      it "orders chunks by chunk_index" do
        question = create(:question)
        chunk2 = create(:chunk, chunkable: question, chunk_index: 2)
        chunk0 = create(:chunk, chunkable: question, chunk_index: 0)
        chunk1 = create(:chunk, chunkable: question, chunk_index: 1)

        expect(described_class.ordered).to eq([ chunk0, chunk1, chunk2 ])
      end
    end

    describe ".embedded" do
      it "returns only chunks with embeddings" do
        embedded = create(:chunk, :embedded)
        _unembedded = create(:chunk, :unembedded)

        expect(described_class.embedded).to contain_exactly(embedded)
      end
    end

    describe ".unembedded" do
      it "returns only chunks without embeddings" do
        _embedded = create(:chunk, :embedded)
        unembedded = create(:chunk, :unembedded)

        expect(described_class.unembedded).to contain_exactly(unembedded)
      end
    end

    describe ".for_chunkable" do
      it "returns chunks for a specific chunkable" do
        question1 = create(:question)
        question2 = create(:question)
        chunk1 = create(:chunk, chunkable: question1, chunk_index: 0)
        _chunk2 = create(:chunk, chunkable: question2, chunk_index: 0)

        expect(described_class.for_chunkable(question1)).to contain_exactly(chunk1)
      end
    end
  end

  describe "#embedded?" do
    it "returns true when chunk has embedding and embedded_at" do
      chunk = build(:chunk, :embedded)
      expect(chunk.embedded?).to be true
    end

    it "returns false when chunk has no embedding" do
      chunk = build(:chunk, :unembedded)
      expect(chunk.embedded?).to be false
    end

    it "returns false when chunk has embedding but no embedded_at" do
      chunk = build(:chunk, embedding: [ 0.1, 0.2 ], embedded_at: nil)
      expect(chunk.embedded?).to be false
    end
  end

  describe "#mark_stale!" do
    it "clears embedding and embedded_at" do
      chunk = create(:chunk, :embedded)
      expect(chunk.embedded?).to be true

      chunk.mark_stale!
      chunk.reload

      expect(chunk.embedding).to be_nil
      expect(chunk.embedded_at).to be_nil
      expect(chunk.embedded?).to be false
    end
  end

  describe "#set_embedding!" do
    it "sets embedding, embedded_at, and embedding_provider" do
      chunk = create(:chunk, :unembedded)
      provider = create(:embedding_provider, :openai)
      vector = Array.new(1536) { rand }

      chunk.set_embedding!(vector, provider: provider)
      chunk.reload

      # Vector values lose some precision when stored in PostgreSQL
      expect(chunk.embedding.length).to eq(vector.length)
      expect(chunk.embedding.first).to be_within(0.0001).of(vector.first)
      expect(chunk.embedded_at).to be_present
      expect(chunk.embedding_provider).to eq(provider)
    end
  end

  describe "metadata accessors" do
    let(:chunk) { build(:chunk, :with_source_metadata) }

    it "#source_type returns the source type from metadata" do
      expect(chunk.source_type).to eq("answer")
    end

    it "#source_id returns the source id from metadata" do
      expect(chunk.source_id).to eq(123)
    end

    it "#position returns the position from metadata" do
      expect(chunk.position).to eq("middle")
    end

    it "returns nil for missing metadata keys" do
      chunk = build(:chunk, metadata: {})
      expect(chunk.source_type).to be_nil
      expect(chunk.source_id).to be_nil
      expect(chunk.position).to be_nil
    end
  end
end
