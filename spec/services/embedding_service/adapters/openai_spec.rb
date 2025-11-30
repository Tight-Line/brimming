# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmbeddingService::Adapters::Openai do
  let(:provider) { build(:embedding_provider, :openai) }
  let(:adapter) { described_class.new(provider) }

  describe "#initialize" do
    it "creates an adapter with a valid provider" do
      expect(adapter.provider).to eq(provider)
    end

    context "without an API key" do
      let(:provider) { build(:embedding_provider, :openai, api_key: nil) }

      it "raises ConfigurationError" do
        expect { adapter }.to raise_error(
          EmbeddingService::Adapters::Base::ConfigurationError,
          "OpenAI adapter requires an API key"
        )
      end
    end
  end

  describe "#embed" do
    let(:texts) { [ "Hello world", "How are you?" ] }
    let(:mock_embeddings) { [ [ 0.1, 0.2, 0.3 ], [ 0.4, 0.5, 0.6 ] ] }

    before do
      stub_request(:post, "https://api.openai.com/v1/embeddings")
        .with(
          headers: { "Authorization" => "Bearer sk-test-key-12345" },
          body: hash_including(
            "model" => "text-embedding-3-small",
            "input" => texts
          )
        )
        .to_return(
          status: 200,
          body: {
            data: [
              { index: 0, embedding: mock_embeddings[0] },
              { index: 1, embedding: mock_embeddings[1] }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "returns embeddings for the texts" do
      result = adapter.embed(texts)
      expect(result).to eq(mock_embeddings)
    end

    it "handles single text input" do
      stub_request(:post, "https://api.openai.com/v1/embeddings")
        .to_return(
          status: 200,
          body: {
            data: [ { index: 0, embedding: mock_embeddings[0] } ]
          }.to_json
        )

      result = adapter.embed("Hello world")
      expect(result).to eq([ mock_embeddings[0] ])
    end

    it "returns empty array for empty input" do
      result = adapter.embed([])
      expect(result).to eq([])
    end
  end

  describe "#embed_one" do
    let(:text) { "Hello world" }
    let(:mock_embedding) { [ 0.1, 0.2, 0.3 ] }

    before do
      stub_request(:post, "https://api.openai.com/v1/embeddings")
        .to_return(
          status: 200,
          body: {
            data: [ { index: 0, embedding: mock_embedding } ]
          }.to_json
        )
    end

    it "returns a single embedding vector" do
      result = adapter.embed_one(text)
      expect(result).to eq(mock_embedding)
    end
  end

  describe "error handling" do
    let(:text) { "Hello world" }

    context "when rate limited" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 429, body: "Rate limit exceeded")
          .then
          .to_return(
            status: 200,
            body: { data: [ { index: 0, embedding: [ 0.1, 0.2 ] } ] }.to_json
          )
      end

      it "retries the request" do
        allow(adapter).to receive(:sleep) # Don't actually sleep in tests

        result = adapter.embed_one(text)
        expect(result).to eq([ 0.1, 0.2 ])
      end
    end

    context "when API returns 401" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 401, body: "Invalid API key")
      end

      it "raises ConfigurationError" do
        expect { adapter.embed_one(text) }.to raise_error(
          EmbeddingService::Adapters::Base::ConfigurationError,
          "Invalid OpenAI API key"
        )
      end
    end

    context "when API returns 500" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 500, body: "Internal server error")
      end

      it "raises ApiError" do
        expect { adapter.embed_one(text) }.to raise_error(
          EmbeddingService::Adapters::Base::ApiError,
          /OpenAI API server error/
        )
      end
    end

    context "when API returns 400" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 400, body: "Bad request")
      end

      it "raises ApiError for client error" do
        expect { adapter.embed_one(text) }.to raise_error(
          EmbeddingService::Adapters::Base::ApiError,
          /OpenAI API client error/
        )
      end
    end

    context "when API returns unexpected code" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 302, body: "Redirect")
      end

      it "raises ApiError for unexpected response" do
        expect { adapter.embed_one(text) }.to raise_error(
          EmbeddingService::Adapters::Base::ApiError,
          /Unexpected OpenAI API response/
        )
      end
    end

    context "when JSON parsing fails" do
      before do
        stub_request(:post, "https://api.openai.com/v1/embeddings")
          .to_return(status: 200, body: "not json")
      end

      it "raises ApiError" do
        expect { adapter.embed_one(text) }.to raise_error(
          EmbeddingService::Adapters::Base::ApiError,
          /Failed to parse OpenAI response/
        )
      end
    end
  end

  describe "custom endpoint" do
    let(:provider) { build(:embedding_provider, :openai, api_endpoint: "https://custom.openai.azure.com/v1") }

    before do
      stub_request(:post, "https://custom.openai.azure.com/v1/embeddings")
        .to_return(
          status: 200,
          body: { data: [ { index: 0, embedding: [ 0.1 ] } ] }.to_json
        )
    end

    it "uses the custom endpoint" do
      adapter.embed_one("test")
      expect(WebMock).to have_requested(:post, "https://custom.openai.azure.com/v1/embeddings")
    end
  end
end
