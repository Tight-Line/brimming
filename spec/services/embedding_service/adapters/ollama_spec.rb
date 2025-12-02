# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmbeddingService::Adapters::Ollama do
  # Stub the endpoint reachability check for all Ollama tests
  before do
    stub_request(:head, "http://localhost:11434/")
      .to_return(status: 200)
    stub_request(:head, "http://custom:8080/")
      .to_return(status: 200)
  end

  let(:provider) do
    create(:embedding_provider, :ollama,
           embedding_model: "nomic-embed-text",
           api_endpoint: "http://localhost:11434",
           dimensions: 768)
  end

  let(:adapter) { described_class.new(provider) }

  describe "#initialize" do
    it "creates adapter with valid provider" do
      expect(adapter).to be_a(described_class)
    end

    context "without api_endpoint" do
      let(:provider) do
        build(:embedding_provider, :ollama,
              embedding_model: "nomic-embed-text",
              api_endpoint: nil,
              dimensions: 768)
      end

      it "raises ConfigurationError" do
        expect { described_class.new(provider) }.to raise_error(
          EmbeddingService::Adapters::Base::ConfigurationError,
          /API endpoint/i
        )
      end
    end
  end

  describe "#embed" do
    let(:mock_response) do
      {
        "embeddings" => [ Array.new(768) { rand } ]
      }.to_json
    end

    before do
      stub_request(:post, "http://localhost:11434/api/embed")
        .to_return(status: 200, body: mock_response)
    end

    it "generates embeddings for texts" do
      result = adapter.embed([ "test text" ])
      expect(result).to be_an(Array)
      expect(result.first.length).to eq(768)
    end

    it "processes multiple texts individually" do
      stub_request(:post, "http://localhost:11434/api/embed")
        .to_return(status: 200, body: mock_response)
        .times(3)

      result = adapter.embed([ "text 1", "text 2", "text 3" ])
      expect(result.length).to eq(3)
    end
  end

  describe "error handling" do
    context "when model not found" do
      before do
        stub_request(:post, "http://localhost:11434/api/embed")
          .to_return(status: 404, body: "model not found")
      end

      it "raises ConfigurationError" do
        expect { adapter.embed([ "test" ]) }.to raise_error(
          EmbeddingService::Adapters::Base::ConfigurationError,
          /not found.*ollama pull/i
        )
      end
    end

    context "when client error" do
      before do
        stub_request(:post, "http://localhost:11434/api/embed")
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
        stub_request(:post, "http://localhost:11434/api/embed")
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
        stub_request(:post, "http://localhost:11434/api/embed")
          .to_return(status: 302, body: "redirect")
      end

      it "raises ApiError" do
        expect { adapter.embed([ "test" ]) }.to raise_error(
          EmbeddingService::Adapters::Base::ApiError,
          /Unexpected.*302/i
        )
      end
    end

    context "when connection refused" do
      before do
        stub_request(:post, "http://localhost:11434/api/embed")
          .to_raise(Errno::ECONNREFUSED)
      end

      it "raises ConfigurationError" do
        expect { adapter.embed([ "test" ]) }.to raise_error(
          EmbeddingService::Adapters::Base::ConfigurationError,
          /Cannot connect.*Ollama running/i
        )
      end
    end

    context "when invalid JSON response" do
      before do
        stub_request(:post, "http://localhost:11434/api/embed")
          .to_return(status: 200, body: "not json")
      end

      it "raises ApiError" do
        expect { adapter.embed([ "test" ]) }.to raise_error(
          EmbeddingService::Adapters::Base::ApiError,
          /Failed to parse/i
        )
      end
    end

    context "when unexpected embeddings format" do
      before do
        stub_request(:post, "http://localhost:11434/api/embed")
          .to_return(status: 200, body: { "embeddings" => "not an array" }.to_json)
      end

      it "raises ApiError" do
        expect { adapter.embed([ "test" ]) }.to raise_error(
          EmbeddingService::Adapters::Base::ApiError,
          /Unexpected.*format/i
        )
      end
    end
  end

  describe "custom endpoint" do
    let(:provider) do
      create(:embedding_provider, :ollama,
             embedding_model: "nomic-embed-text",
             api_endpoint: "http://custom:8080",
             dimensions: 768)
    end

    let(:mock_response) do
      { "embeddings" => [ Array.new(768) { rand } ] }.to_json
    end

    before do
      stub_request(:post, "http://custom:8080/api/embed")
        .to_return(status: 200, body: mock_response)
    end

    it "uses custom endpoint" do
      adapter.embed([ "test" ])
      expect(WebMock).to have_requested(:post, "http://custom:8080/api/embed")
    end
  end
end
