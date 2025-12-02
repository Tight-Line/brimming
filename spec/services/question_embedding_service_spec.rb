# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionEmbeddingService do
  let(:provider) { create(:embedding_provider, :openai) }
  let(:question) { create(:question) }
  let(:mock_embedding) { Array.new(provider.dimensions) { rand } }

  before do
    # Mock the embedding service
    allow_any_instance_of(EmbeddingService::Client).to receive(:embed_one).and_return(mock_embedding)
  end

  describe ".embed" do
    context "with no provider available" do
      before do
        EmbeddingProvider.destroy_all
      end

      it "returns error when no provider is available" do
        result = described_class.embed(question)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("No embedding provider available")
      end
    end

    context "with empty content" do
      before do
        allow(EmbeddingService).to receive(:prepare_question_text).and_return("")
      end

      it "returns success with 0 chunks when no content to embed" do
        result = described_class.embed(question, provider: provider)
        expect(result[:success]).to be true
        expect(result[:chunks]).to eq(0)
        expect(result[:message]).to eq("No content to embed")
      end
    end

    context "with valid question" do
      it "creates chunks for the question" do
        result = described_class.embed(question, provider: provider)
        expect(result[:success]).to be true
        expect(result[:chunks]).to be >= 1
        expect(question.chunks.count).to be >= 1
      end

      it "sets embeddings on chunks" do
        described_class.embed(question, provider: provider)
        expect(question.chunks.first.embedded?).to be true
      end

      it "stores provider reference on chunks" do
        described_class.embed(question, provider: provider)
        expect(question.chunks.first.embedding_provider).to eq(provider)
      end

      it "stores chunk metadata including position" do
        described_class.embed(question, provider: provider)
        expect(question.chunks.first.metadata["position"]).to be_present
      end

      it "updates embedded_at timestamp on question" do
        described_class.embed(question, provider: provider)
        question.reload
        expect(question.embedded_at).to be_present
      end

      it "removes old chunks before creating new ones" do
        # Create initial chunks
        described_class.embed(question, provider: provider)
        initial_count = question.chunks.count
        initial_ids = question.chunks.pluck(:id)

        # Re-embed
        described_class.embed(question, provider: provider)

        # Old chunks should be gone, new ones created
        expect(question.reload.chunks.count).to eq(initial_count)
        expect(question.chunks.pluck(:id)).not_to match_array(initial_ids)
      end
    end

    context "with question and best answer" do
      let(:question_with_answer) { create(:question) }

      before do
        create(:answer, question: question_with_answer, is_correct: true, body: "This is the best answer content.")
      end

      it "includes best answer in chunk content" do
        described_class.embed(question_with_answer, provider: provider)
        chunk_content = question_with_answer.chunks.map(&:content).join
        expect(chunk_content).to include("Best Answer")
      end
    end

    context "with long question requiring multiple chunks" do
      let(:long_body) { "Test content. " * 500 }
      let(:long_question) { create(:question, body: long_body) }

      before do
        provider.update!(chunk_size: 50) # Small chunks for testing
      end

      it "creates multiple chunks" do
        result = described_class.embed(long_question, provider: provider)
        expect(result[:success]).to be true
        expect(result[:chunks]).to be > 1
      end

      it "assigns sequential chunk indices" do
        described_class.embed(long_question, provider: provider)
        indices = long_question.chunks.ordered.pluck(:chunk_index)
        expect(indices).to eq((0...indices.length).to_a)
      end
    end

    context "when embedding service raises an error" do
      before do
        allow_any_instance_of(EmbeddingService::Client)
          .to receive(:embed_one)
          .and_raise(EmbeddingService::Client::Error, "API error")
      end

      it "returns error response" do
        result = described_class.embed(question, provider: provider)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("API error")
      end
    end

    context "with specific provider" do
      let(:other_provider) { create(:embedding_provider, :openai, name: "Other OpenAI") }

      it "uses the specified provider" do
        described_class.embed(question, provider: other_provider)
        expect(question.chunks.first.embedding_provider).to eq(other_provider)
      end
    end
  end
end
