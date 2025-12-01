# frozen_string_literal: true

require "rails_helper"

RSpec.describe GenerateArticleEmbeddingJob do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
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
    it "generates chunks for the article" do
      expect(article.chunks).to be_empty

      described_class.new.perform(article)

      article.reload
      expect(article.chunks).to be_present
    end

    it "creates chunks with embeddings for the article" do
      expect(article.chunks).to be_empty

      described_class.new.perform(article)

      article.reload
      expect(article.chunks).to be_present
      expect(article.chunks.first.embedding).to be_present
      expect(article.chunks.first.embedding_provider).to eq(provider)
    end

    it "skips if article already has chunks from the current provider" do
      # Create existing chunks
      create(:chunk, :embedded, chunkable: article, embedding_provider: provider)

      expect(ArticleEmbeddingService).not_to receive(:embed)

      described_class.new.perform(article)
    end

    it "re-embeds if article has chunks from a different provider" do
      other_provider = create(:embedding_provider, :cohere)
      create(:chunk, :embedded, chunkable: article, embedding_provider: other_provider)

      described_class.new.perform(article)

      article.reload
      # Should have new chunks from current provider (old ones deleted)
      expect(article.chunks.first.embedding_provider).to eq(provider)
    end

    it "regenerates embedding when force is true" do
      # Create existing chunks
      create(:chunk, :embedded, chunkable: article, embedding_provider: provider)

      expect(ArticleEmbeddingService).to receive(:embed).and_call_original

      described_class.new.perform(article, force: true)
    end

    it "skips deleted articles" do
      article.update!(deleted_at: Time.current)

      expect(ArticleEmbeddingService).not_to receive(:embed)

      described_class.new.perform(article)
    end

    context "when no embedding provider is configured" do
      before do
        EmbeddingProvider.delete_all
      end

      it "skips without error" do
        expect { described_class.new.perform(article) }.not_to raise_error
        expect(article.reload.chunks).to be_empty
      end
    end

    context "when embedding service returns error" do
      before do
        allow(ArticleEmbeddingService).to receive(:embed).and_return(
          { success: false, error: "Test error" }
        )
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Failed to embed.*Test error/)

        described_class.new.perform(article)
      end
    end

    context "when API returns a server error" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "logs error message from service" do
        expect(Rails.logger).to receive(:error).with(/Failed to embed.*server error/i)

        described_class.new.perform(article)

        expect(article.reload.chunks).to be_empty
      end
    end

    context "when API key is invalid" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 401, body: "Invalid API key")
      end

      it "logs error and does not retry" do
        expect(Rails.logger).to receive(:error).with(/Failed to embed.*Invalid.*API key/i)

        described_class.new.perform(article)

        expect(article.reload.chunks).to be_empty
      end
    end

    context "when configuration error occurs" do
      before do
        allow(ArticleEmbeddingService).to receive(:embed).and_raise(
          EmbeddingService::Adapters::Base::ConfigurationError.new("Bad config")
        )
      end

      it "logs configuration error and does not retry" do
        expect(Rails.logger).to receive(:error).with(/Configuration error.*Bad config/)

        # Should not raise
        described_class.new.perform(article)
      end
    end
  end

  describe "queue configuration" do
    it "uses the embeddings queue" do
      expect(described_class.new.queue_name).to eq("embeddings")
    end
  end
end
