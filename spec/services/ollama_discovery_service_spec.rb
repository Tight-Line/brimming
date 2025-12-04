# frozen_string_literal: true

require "rails_helper"

RSpec.describe OllamaDiscoveryService do
  describe ".reachable?" do
    it "returns true when endpoint responds successfully" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 200, body: '{"models":[]}')

      expect(described_class.reachable?("http://localhost:11434")).to be true
    end

    it "returns false when endpoint returns error" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 500)

      expect(described_class.reachable?("http://localhost:11434")).to be false
    end

    it "returns false when connection refused" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_raise(Errno::ECONNREFUSED)

      expect(described_class.reachable?("http://localhost:11434")).to be false
    end

    it "returns false when timeout" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_raise(Net::OpenTimeout)

      expect(described_class.reachable?("http://localhost:11434")).to be false
    end
  end

  describe ".detect_endpoint" do
    it "returns first reachable endpoint" do
      # First endpoint fails
      stub_request(:get, "http://host.docker.internal:11434/api/tags")
        .to_raise(Errno::ECONNREFUSED)

      # Second endpoint succeeds
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 200, body: '{"models":[]}')

      expect(described_class.detect_endpoint).to eq("http://localhost:11434")
    end

    it "returns nil when no endpoints reachable" do
      OllamaDiscoveryService::DEFAULT_ENDPOINTS.each do |endpoint|
        stub_request(:get, "#{endpoint}/api/tags")
          .to_raise(Errno::ECONNREFUSED)
      end

      expect(described_class.detect_endpoint).to be_nil
    end
  end

  describe ".fetch_models" do
    let(:models_response) do
      {
        "models" => [
          {
            "name" => "llama3.2:latest",
            "model" => "llama3.2:latest",
            "size" => 2_000_000_000,
            "details" => {
              "parameter_size" => "3B",
              "family" => "llama",
              "quantization_level" => "Q4_K_M"
            }
          },
          {
            "name" => "mistral:7b",
            "model" => "mistral:7b",
            "size" => 4_000_000_000,
            "details" => {
              "parameter_size" => "7B",
              "family" => "mistral",
              "quantization_level" => "Q4_0"
            }
          },
          {
            "name" => "nomic-embed-text:latest",
            "model" => "nomic-embed-text:latest",
            "size" => 500_000_000,
            "details" => {
              "parameter_size" => "137M",
              "family" => "nomic-bert"
            }
          },
          {
            "name" => "mxbai-embed-large:latest",
            "model" => "mxbai-embed-large:latest",
            "size" => 600_000_000,
            "details" => {
              "parameter_size" => "335M",
              "family" => "bert"
            }
          }
        ]
      }
    end

    it "returns parsed model information" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 200, body: models_response.to_json)

      models = described_class.fetch_models("http://localhost:11434")

      expect(models.length).to eq(2)
      expect(models.first).to include(
        name: "llama3.2:latest",
        parameter_size: "3B",
        family: "llama",
        quantization: "Q4_K_M"
      )
    end

    it "filters out embedding models by default" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 200, body: models_response.to_json)

      models = described_class.fetch_models("http://localhost:11434")

      model_names = models.map { |m| m[:name] }
      expect(model_names).to include("llama3.2:latest", "mistral:7b")
      expect(model_names).not_to include("nomic-embed-text:latest", "mxbai-embed-large:latest")
    end

    it "returns only embedding models when type is :embedding" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 200, body: models_response.to_json)

      models = described_class.fetch_models("http://localhost:11434", type: :embedding)

      model_names = models.map { |m| m[:name] }
      expect(model_names).to include("mxbai-embed-large:latest", "nomic-embed-text:latest")
      expect(model_names).not_to include("llama3.2:latest", "mistral:7b")
    end

    it "returns all models when type is :all" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 200, body: models_response.to_json)

      models = described_class.fetch_models("http://localhost:11434", type: :all)

      expect(models.length).to eq(4)
    end

    it "sorts models alphabetically by name" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 200, body: models_response.to_json)

      models = described_class.fetch_models("http://localhost:11434")

      expect(models.map { |m| m[:name] }).to eq([ "llama3.2:latest", "mistral:7b" ])
    end

    it "raises error on HTTP failure" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 500, body: "Internal Server Error")

      expect {
        described_class.fetch_models("http://localhost:11434")
      }.to raise_error(OllamaDiscoveryService::Error, /HTTP 500/)
    end

    it "raises error on invalid JSON" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 200, body: "not json")

      expect {
        described_class.fetch_models("http://localhost:11434")
      }.to raise_error(OllamaDiscoveryService::Error, /Invalid JSON/)
    end

    it "raises error on connection failure" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_raise(Errno::ECONNREFUSED)

      expect {
        described_class.fetch_models("http://localhost:11434")
      }.to raise_error(OllamaDiscoveryService::Error, /Failed to connect/)
    end

    it "handles empty models array" do
      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 200, body: '{"models":[]}')

      models = described_class.fetch_models("http://localhost:11434")

      expect(models).to eq([])
    end

    it "handles missing details gracefully" do
      response = {
        "models" => [
          { "name" => "simple-model" }
        ]
      }

      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 200, body: response.to_json)

      models = described_class.fetch_models("http://localhost:11434")

      expect(models.first).to include(
        name: "simple-model",
        parameter_size: nil,
        family: nil
      )
    end
  end

  describe ".fetch_model_names" do
    it "returns just the model names" do
      response = {
        "models" => [
          { "name" => "llama3.2:latest" },
          { "name" => "mistral:7b" }
        ]
      }

      stub_request(:get, "http://localhost:11434/api/tags")
        .to_return(status: 200, body: response.to_json)

      names = described_class.fetch_model_names("http://localhost:11434")

      expect(names).to eq([ "llama3.2:latest", "mistral:7b" ])
    end
  end
end
