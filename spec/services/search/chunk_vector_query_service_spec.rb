# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search::ChunkVectorQueryService do
  let(:provider) { create(:embedding_provider, :openai, similarity_threshold: 0.5) }
  let(:query_embedding) { Array.new(provider.dimensions) { rand } }

  before do
    allow_any_instance_of(EmbeddingService::Client).to receive(:embed_one).and_return(query_embedding)
  end

  describe "#call" do
    context "with empty query" do
      it "returns empty result" do
        result = described_class.new(q: "").call
        expect(result.hits).to be_empty
        expect(result.total).to eq(0)
      end

      it "returns empty result for whitespace-only query" do
        result = described_class.new(q: "   ").call
        expect(result.hits).to be_empty
      end
    end

    context "with no embedding provider" do
      before { EmbeddingProvider.destroy_all }

      it "returns empty result" do
        result = described_class.new(q: "test query").call
        expect(result.hits).to be_empty
      end
    end

    context "with no query embedding generated" do
      before do
        allow_any_instance_of(EmbeddingService::Client)
          .to receive(:embed_one)
          .and_raise(EmbeddingService::Client::NoProviderError)
      end

      it "returns empty result" do
        result = described_class.new(q: "test query").call
        expect(result.hits).to be_empty
      end
    end

    context "with embedded chunks" do
      let(:question) { create(:question) }
      let(:chunk) { create(:chunk, :embedded, chunkable: question, embedding_provider: provider) }

      before do
        # Mock the entire find_similar_chunks method
        mock_chunk = double("chunk",
                            chunkable: question,
                            chunkable_type: "Question",
                            chunkable_id: question.id,
                            neighbor_distance: 0.2,
                            present?: true)
        allow(mock_chunk).to receive(:chunkable).and_return(question)

        allow_any_instance_of(described_class).to receive(:find_similar_chunks)
          .and_return([ mock_chunk ])
      end

      it "returns hits for embedded chunks" do
        result = described_class.new(q: "test query").call
        expect(result.hits).not_to be_empty
      end

      it "includes type in hit" do
        result = described_class.new(q: "test query").call
        expect(result.hits.first.type).to eq("Question")
      end

      it "includes chunkable in hit" do
        result = described_class.new(q: "test query").call
        expect(result.hits.first.chunkable).to eq(question)
      end

      it "calculates similarity score from distance" do
        result = described_class.new(q: "test query").call
        # distance 0.2 -> similarity 0.8
        expect(result.hits.first.score).to eq(0.8)
      end
    end

    context "grouping chunks by chunkable" do
      let(:question) { create(:question) }

      before do
        # Mock two chunks for the same question
        chunk1 = double("chunk1",
                        chunkable: question,
                        chunkable_type: "Question",
                        chunkable_id: question.id,
                        neighbor_distance: 0.2, # similarity 0.8
                        present?: true)
        chunk2 = double("chunk2",
                        chunkable: question,
                        chunkable_type: "Question",
                        chunkable_id: question.id,
                        neighbor_distance: 0.4, # similarity 0.6
                        present?: true)

        allow_any_instance_of(described_class).to receive(:find_similar_chunks)
          .and_return([ chunk1, chunk2 ])
      end

      it "returns one hit per chunkable" do
        result = described_class.new(q: "test query").call
        expect(result.hits.length).to eq(1)
      end

      it "uses best score for grouped chunks" do
        result = described_class.new(q: "test query").call
        # Should use the better score (0.8, not 0.6)
        expect(result.hits.first.score).to eq(0.8)
      end
    end

    context "filtering by space" do
      let(:space) { create(:space) }
      let(:other_space) { create(:space) }
      let(:question_in_space) { create(:question, space: space) }
      let(:question_other) { create(:question, space: other_space) }

      before do
        chunk1 = double("chunk1",
                        chunkable: question_in_space,
                        chunkable_type: "Question",
                        chunkable_id: question_in_space.id,
                        neighbor_distance: 0.2,
                        present?: true)
        chunk2 = double("chunk2",
                        chunkable: question_other,
                        chunkable_type: "Question",
                        chunkable_id: question_other.id,
                        neighbor_distance: 0.2,
                        present?: true)

        allow_any_instance_of(described_class).to receive(:find_similar_chunks)
          .and_return([ chunk1, chunk2 ])
      end

      it "filters questions by space_id" do
        result = described_class.new(q: "test query", space_id: space.id).call
        expect(result.hits.length).to eq(1)
        expect(result.hits.first.chunkable).to eq(question_in_space)
      end
    end

    context "filtering articles by space" do
      let(:space) { create(:space) }
      let(:article_in_space) { create(:article) }
      let(:article_other) { create(:article) }

      before do
        create(:article_space, article: article_in_space, space: space)

        chunk1 = double("chunk1",
                        chunkable: article_in_space,
                        chunkable_type: "Article",
                        chunkable_id: article_in_space.id,
                        neighbor_distance: 0.2,
                        present?: true)
        chunk2 = double("chunk2",
                        chunkable: article_other,
                        chunkable_type: "Article",
                        chunkable_id: article_other.id,
                        neighbor_distance: 0.2,
                        present?: true)

        allow_any_instance_of(described_class).to receive(:find_similar_chunks)
          .and_return([ chunk1, chunk2 ])
      end

      it "filters articles by space_id" do
        result = described_class.new(q: "test query", space_id: space.id).call
        expect(result.hits.length).to eq(1)
        expect(result.hits.first.chunkable).to eq(article_in_space)
      end
    end

    context "similarity threshold" do
      let(:question) { create(:question) }

      before do
        # Mock chunk with low similarity (0.3 = 1 - 0.7)
        chunk = double("chunk",
                       chunkable: question,
                       chunkable_type: "Question",
                       chunkable_id: question.id,
                       neighbor_distance: 0.7, # similarity = 0.3
                       present?: true)

        allow_any_instance_of(described_class).to receive(:find_similar_chunks)
          .and_return([ chunk ])
      end

      it "filters out results below threshold" do
        # Default threshold is 0.5, similarity is 0.3
        result = described_class.new(q: "test query").call
        expect(result.hits).to be_empty
      end

      it "uses provider threshold" do
        result = described_class.new(q: "test query").call
        expect(result.similarity_threshold).to eq(0.5)
      end

      it "uses custom threshold when provided" do
        result = described_class.new(q: "test query", similarity_threshold: 0.2).call
        expect(result.similarity_threshold).to eq(0.2)
        expect(result.hits).not_to be_empty
      end
    end

    context "pagination" do
      let(:questions) { create_list(:question, 5) }

      before do
        chunks = questions.map.with_index do |q, i|
          double("chunk#{i}",
                 chunkable: q,
                 chunkable_type: "Question",
                 chunkable_id: q.id,
                 neighbor_distance: 0.1 + (i * 0.01), # slightly different scores
                 present?: true)
        end

        allow_any_instance_of(described_class).to receive(:find_similar_chunks)
          .and_return(chunks)
      end

      it "respects limit parameter" do
        result = described_class.new(q: "test query", limit: 2).call
        expect(result.hits.length).to eq(2)
      end

      it "respects offset parameter" do
        result = described_class.new(q: "test query", offset: 2, limit: 2).call
        expect(result.hits.length).to eq(2)
      end
    end

    context "error handling" do
      it "handles embedding API errors gracefully" do
        allow_any_instance_of(EmbeddingService::Client)
          .to receive(:embed_one)
          .and_raise(EmbeddingService::Adapters::Base::ApiError, "API error")

        result = described_class.new(q: "test query").call
        expect(result.hits).to be_empty
      end

      it "handles unexpected errors gracefully" do
        allow_any_instance_of(EmbeddingService::Client)
          .to receive(:embed_one)
          .and_raise(StandardError, "Unexpected error")

        result = described_class.new(q: "test query").call
        expect(result.hits).to be_empty
      end
    end

    context "with deleted chunkables" do
      before do
        chunk = double("chunk", chunkable: nil, present?: true)

        allow_any_instance_of(described_class).to receive(:find_similar_chunks)
          .and_return([ chunk ])
      end

      it "skips chunks with missing chunkables" do
        result = described_class.new(q: "test query").call
        expect(result.hits).to be_empty
      end
    end

    context "fallback similarity threshold" do
      before do
        EmbeddingProvider.destroy_all
        allow(EmbeddingService).to receive(:available?).and_return(true)
      end

      it "uses fallback threshold when no provider" do
        result = described_class.new(q: "test query").call
        expect(result.similarity_threshold).to eq(described_class::FALLBACK_SIMILARITY_THRESHOLD)
      end
    end

    context "with real chunk database queries" do
      let(:question) { create(:question) }
      let!(:embedded_chunk) do
        create(:chunk, chunkable: question, embedding_provider: provider).tap do |c|
          c.set_embedding!(query_embedding, provider: provider)
        end
      end

      it "queries chunks from the database without type filter" do
        # types defaults to %w[Question Article] which tests the branch
        result = described_class.new(q: "test query").call
        expect(result).to be_present
      end

      it "queries chunks when types is empty array" do
        # Empty types array should not filter (tests else branch)
        result = described_class.new(q: "test query", types: []).call
        expect(result).to be_present
      end

      it "filters by type when specified" do
        result = described_class.new(q: "test query", types: [ "Article" ]).call
        # Should not find Question chunks
        expect(result.hits.select { |h| h.type == "Question" }).to be_empty
      end
    end

    context "filtering unknown chunkable types" do
      # Test the else branch of filtered_out? by creating a scenario
      # where chunkable type is neither Question nor Article

      before do
        # Create a mock chunkable that is neither Question nor Article
        other_chunkable = double("other_chunkable", id: 123)
        allow(other_chunkable).to receive(:is_a?).with(Question).and_return(false)
        allow(other_chunkable).to receive(:is_a?).with(Article).and_return(false)
        allow(other_chunkable).to receive(:class).and_return(Class.new { def self.name; "OtherType"; end })

        chunk = double("chunk",
                       chunkable: other_chunkable,
                       chunkable_type: "OtherType",
                       chunkable_id: 123,
                       neighbor_distance: 0.2,
                       present?: true)

        allow_any_instance_of(described_class).to receive(:find_similar_chunks)
          .and_return([ chunk ])
      end

      it "does not filter out unknown types" do
        result = described_class.new(q: "test query", space_id: 999).call
        # Unknown types are not filtered by space
        expect(result.hits).not_to be_empty
      end
    end
  end
end
