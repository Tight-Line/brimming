# frozen_string_literal: true

require "rails_helper"

RSpec.describe GenerateQuestionEmbeddingJob do
  let(:space) { create(:space) }
  let(:user) { create(:user) }
  let(:question) { create(:question, space: space, user: user) }
  let(:provider) { create(:embedding_provider, :openai, :enabled) }
  let(:mock_embedding) { Array.new(1536) { rand } }

  before do
    provider

    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: {
          data: [ { index: 0, embedding: mock_embedding } ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  describe "#perform" do
    it "generates chunks and updates embedded_at for the question" do
      expect(question.chunks).to be_empty
      expect(question.embedded_at).to be_nil

      described_class.new.perform(question)

      question.reload
      expect(question.chunks).to be_present
      expect(question.embedded_at).to be_present
    end

    it "creates chunks with embeddings for the question" do
      expect(question.chunks).to be_empty

      described_class.new.perform(question)

      question.reload
      expect(question.chunks).to be_present
      expect(question.chunks.first.embedding).to be_present
      expect(question.chunks.first.embedding_provider).to eq(provider)
    end

    it "skips if question already has chunks from the current provider" do
      # Create existing chunks
      create(:chunk, :embedded, chunkable: question, embedding_provider: provider)

      expect(QuestionEmbeddingService).not_to receive(:embed)

      described_class.new.perform(question)
    end

    it "re-embeds if question has chunks from a different provider" do
      other_provider = create(:embedding_provider, :cohere)
      create(:chunk, :embedded, chunkable: question, embedding_provider: other_provider)

      described_class.new.perform(question)

      question.reload
      # Should have new chunks from current provider (old ones deleted)
      expect(question.chunks.first.embedding_provider).to eq(provider)
    end

    it "regenerates embedding when force is true" do
      # Create existing chunks
      create(:chunk, :embedded, chunkable: question, embedding_provider: provider)
      question.update!(embedded_at: 1.hour.ago)
      old_embedded_at = question.embedded_at

      described_class.new.perform(question, force: true)

      question.reload
      expect(question.embedded_at).to be > old_embedded_at
    end

    it "skips deleted questions" do
      question.update!(deleted_at: Time.current)

      expect(QuestionEmbeddingService).not_to receive(:embed)

      described_class.new.perform(question)
    end

    context "when no embedding provider is configured" do
      before do
        EmbeddingProvider.delete_all
      end

      it "skips without error" do
        expect { described_class.new.perform(question) }.not_to raise_error
        expect(question.reload.chunks).to be_empty
      end
    end

    context "when embedding service returns error" do
      before do
        allow(QuestionEmbeddingService).to receive(:embed).and_return(
          { success: false, error: "Test error" }
        )
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Failed to embed.*Test error/)

        described_class.new.perform(question)
      end
    end

    context "when API returns an error" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "logs error message from service" do
        expect(Rails.logger).to receive(:error).with(/Failed to embed.*server error/i)

        described_class.new.perform(question)

        expect(question.reload.chunks).to be_empty
      end
    end

    context "when API key is invalid" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 401, body: "Invalid API key")
      end

      it "logs error and does not retry" do
        expect(Rails.logger).to receive(:error).with(/Failed to embed.*Invalid.*API key/i)

        described_class.new.perform(question)

        expect(question.reload.chunks).to be_empty
      end
    end
  end

  describe "queue configuration" do
    it "uses the embeddings queue" do
      expect(described_class.new.queue_name).to eq("embeddings")
    end
  end
end
