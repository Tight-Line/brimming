# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmbeddingService::Adapters::Cohere do
  let(:provider) do
    create(:embedding_provider, :cohere,
           embedding_model: "embed-english-v3.0",
           api_key: "test-api-key",
           dimensions: 1024)
  end

  let(:adapter) { described_class.new(provider) }

  describe "#initialize" do
    it "creates adapter with valid provider" do
      expect(adapter).to be_a(described_class)
    end

    context "without api_key" do
      let(:provider) do
        build(:embedding_provider, :cohere,
              embedding_model: "embed-english-v3.0",
              api_key: nil,
              dimensions: 1024)
      end

      it "raises ConfigurationError" do
        expect { described_class.new(provider) }.to raise_error(
          EmbeddingService::Adapters::Base::ConfigurationError,
          /API key/i
        )
      end
    end
  end

  describe "#embed" do
    let(:mock_embeddings) { [ Array.new(1024) { rand }, Array.new(1024) { rand } ] }

    context "with v3 model" do
      let(:mock_response) do
        {
          "embeddings" => {
            "float" => mock_embeddings
          }
        }.to_json
      end

      before do
        stub_request(:post, "https://api.cohere.com/v1/embed")
          .to_return(status: 200, body: mock_response)
      end

      it "generates embeddings for texts" do
        result = adapter.embed([ "text 1", "text 2" ])
        expect(result).to eq(mock_embeddings)
      end

      it "includes embedding_types for v3 models" do
        adapter.embed([ "test" ])
        expect(WebMock).to have_requested(:post, "https://api.cohere.com/v1/embed")
          .with(body: hash_including("embedding_types" => [ "float" ]))
      end
    end

    context "with v2 model" do
      let(:provider) do
        create(:embedding_provider, :cohere,
               embedding_model: "embed-english-v2.0",
               api_key: "test-api-key",
               dimensions: 4096)
      end

      let(:mock_response) do
        { "embeddings" => mock_embeddings }.to_json
      end

      before do
        stub_request(:post, "https://api.cohere.com/v1/embed")
          .to_return(status: 200, body: mock_response)
      end

      it "returns embeddings directly" do
        result = adapter.embed([ "text 1", "text 2" ])
        expect(result).to eq(mock_embeddings)
      end

      it "does not include embedding_types" do
        adapter.embed([ "test" ])
        expect(WebMock).to have_requested(:post, "https://api.cohere.com/v1/embed")
          .with { |req| !JSON.parse(req.body).key?("embedding_types") }
      end
    end
  end

  describe "error handling" do
    context "when rate limited" do
      before do
        stub_request(:post, "https://api.cohere.com/v1/embed")
          .to_return(status: 429, body: "rate limited")
      end

      it "raises RateLimitError" do
        expect { adapter.embed([ "test" ]) }.to raise_error(
          EmbeddingService::Adapters::Base::RateLimitError,
          /rate limit/i
        )
      end
    end

    context "when unauthorized" do
      before do
        stub_request(:post, "https://api.cohere.com/v1/embed")
          .to_return(status: 401, body: "unauthorized")
      end

      it "raises ConfigurationError" do
        expect { adapter.embed([ "test" ]) }.to raise_error(
          EmbeddingService::Adapters::Base::ConfigurationError,
          /Invalid.*API key/i
        )
      end
    end

    context "when client error" do
      before do
        stub_request(:post, "https://api.cohere.com/v1/embed")
          .to_return(status: 400, body: "bad request")
      end

      it "raises ApiError" do
        expect { adapter.embed([ "test" ]) }.to raise_error(
          EmbeddingService::Adapters::Base::ApiError,
          /client error.*400/i
        )
      end
    end

    context "when server error" do
      before do
        stub_request(:post, "https://api.cohere.com/v1/embed")
          .to_return(status: 500, body: "internal error")
      end

      it "raises ApiError" do
        expect { adapter.embed([ "test" ]) }.to raise_error(
          EmbeddingService::Adapters::Base::ApiError,
          /server error.*500/i
        )
      end
    end

    context "when unexpected response code" do
      before do
        stub_request(:post, "https://api.cohere.com/v1/embed")
          .to_return(status: 302, body: "redirect")
      end

      it "raises ApiError" do
        expect { adapter.embed([ "test" ]) }.to raise_error(
          EmbeddingService::Adapters::Base::ApiError,
          /Unexpected.*302/i
        )
      end
    end

    context "when invalid JSON response" do
      before do
        stub_request(:post, "https://api.cohere.com/v1/embed")
          .to_return(status: 200, body: "not json")
      end

      it "raises ApiError" do
        expect { adapter.embed([ "test" ]) }.to raise_error(
          EmbeddingService::Adapters::Base::ApiError,
          /Failed to parse/i
        )
      end
    end
  end

  describe "custom endpoint" do
    let(:provider) do
      create(:embedding_provider, :cohere,
             embedding_model: "embed-english-v3.0",
             api_key: "test-api-key",
             api_endpoint: "https://custom.cohere.com/v1",
             dimensions: 1024)
    end

    let(:mock_response) do
      { "embeddings" => { "float" => [ Array.new(1024) { rand } ] } }.to_json
    end

    before do
      stub_request(:post, "https://custom.cohere.com/v1/embed")
        .to_return(status: 200, body: mock_response)
    end

    it "uses custom endpoint" do
      adapter.embed([ "test" ])
      expect(WebMock).to have_requested(:post, "https://custom.cohere.com/v1/embed")
    end
  end

  describe "authorization header" do
    let(:mock_response) do
      { "embeddings" => { "float" => [ Array.new(1024) { rand } ] } }.to_json
    end

    before do
      stub_request(:post, "https://api.cohere.com/v1/embed")
        .to_return(status: 200, body: mock_response)
    end

    it "includes Bearer token" do
      adapter.embed([ "test" ])
      expect(WebMock).to have_requested(:post, "https://api.cohere.com/v1/embed")
        .with(headers: { "Authorization" => "Bearer test-api-key" })
    end
  end
end
