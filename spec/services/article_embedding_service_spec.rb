# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArticleEmbeddingService do
  let(:provider) { create(:embedding_provider, :openai) }
  let(:article) { create(:article, body: "This is test content for embedding.") }
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
        result = described_class.embed(article)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("No embedding provider available")
      end
    end

    context "with empty content" do
      let(:article) { create(:article, body: "") }

      it "returns success with 0 chunks when no content to embed" do
        result = described_class.embed(article, provider: provider)
        expect(result[:success]).to be true
        expect(result[:chunks]).to eq(0)
        expect(result[:message]).to eq("No content to embed")
      end
    end

    context "with valid content" do
      it "creates chunks for the article" do
        result = described_class.embed(article, provider: provider)
        expect(result[:success]).to be true
        expect(result[:chunks]).to be >= 1
        expect(article.chunks.count).to be >= 1
      end

      it "sets embeddings on chunks" do
        described_class.embed(article, provider: provider)
        expect(article.chunks.first.embedded?).to be true
      end

      it "stores provider reference on chunks" do
        described_class.embed(article, provider: provider)
        expect(article.chunks.first.embedding_provider).to eq(provider)
      end

      it "stores chunk metadata including position" do
        described_class.embed(article, provider: provider)
        expect(article.chunks.first.metadata["position"]).to be_present
      end

      it "removes old chunks before creating new ones" do
        # Create initial chunks
        described_class.embed(article, provider: provider)
        initial_count = article.chunks.count
        initial_ids = article.chunks.pluck(:id)

        # Re-embed
        described_class.embed(article, provider: provider)

        # Old chunks should be gone, new ones created
        expect(article.reload.chunks.count).to eq(initial_count)
        expect(article.chunks.pluck(:id)).not_to match_array(initial_ids)
      end
    end

    context "with long content requiring multiple chunks" do
      let(:long_content) { "Test content. " * 500 }
      let(:article) { create(:article, body: long_content) }

      before do
        provider.update!(chunk_size: 50) # Small chunks for testing
      end

      it "creates multiple chunks" do
        result = described_class.embed(article, provider: provider)
        expect(result[:success]).to be true
        expect(result[:chunks]).to be > 1
      end

      it "assigns sequential chunk indices" do
        described_class.embed(article, provider: provider)
        indices = article.chunks.ordered.pluck(:chunk_index)
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
        result = described_class.embed(article, provider: provider)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("API error")
      end
    end

    context "with specific provider" do
      let(:other_provider) { create(:embedding_provider, :openai, name: "Other OpenAI") }

      it "uses the specified provider" do
        described_class.embed(article, provider: other_provider)
        expect(article.chunks.first.embedding_provider).to eq(other_provider)
      end
    end
  end
end
