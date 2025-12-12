# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmbeddingProvider do
  describe "validations" do
    subject { build(:embedding_provider) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:provider_type) }
    it { is_expected.to validate_inclusion_of(:provider_type).in_array(EmbeddingProvider::PROVIDER_TYPES) }
    it { is_expected.to validate_presence_of(:embedding_model) }

    # Dimensions are auto-derived from model selection but still validated
    it "auto-derives dimensions from embedding model" do
      provider = build(:embedding_provider, provider_type: "openai", embedding_model: "text-embedding-3-large", dimensions: nil)
      provider.valid?
      expect(provider.dimensions).to eq(3072)
    end

    it "validates dimensions is present (after derivation)" do
      provider = build(:embedding_provider, provider_type: "openai", embedding_model: "unknown-model", dimensions: nil)
      expect(provider).not_to be_valid
      expect(provider.errors[:dimensions]).to include("can't be blank")
    end

    it "validates dimensions is within range" do
      # Use unknown model to prevent auto-derivation from overwriting test values
      provider = build(:embedding_provider, embedding_model: "custom-model", dimensions: 0)
      expect(provider).not_to be_valid
      expect(provider.errors[:dimensions]).to include("must be greater than 0")

      provider = build(:embedding_provider, embedding_model: "custom-model", dimensions: 5000)
      expect(provider).not_to be_valid
      expect(provider.errors[:dimensions]).to include("must be less than or equal to 4096")
    end

    it "validates api_endpoint is required for azure_openai" do
      provider = build(:embedding_provider, provider_type: "azure_openai", api_key: "test", embedding_model: "text-embedding-ada-002", dimensions: 1536, api_endpoint: "")
      expect(provider).not_to be_valid
      expect(provider.errors[:api_endpoint]).to include("is required for Azure OpenAI")
    end

    describe "api_endpoint reachability" do
      it "validates endpoint is reachable when creating with api_endpoint" do
        stub_request(:any, "http://unreachable-host.invalid:11434/").to_raise(SocketError.new("getaddrinfo: nodename nor servname provided"))

        provider = build(:embedding_provider, :ollama, api_endpoint: "http://unreachable-host.invalid:11434")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint].first).to include("could not resolve host")
      end

      it "validates endpoint is reachable when updating api_endpoint" do
        stub_request(:any, "http://localhost:11434/").to_return(status: 200)
        provider = create(:embedding_provider, :ollama, api_endpoint: "http://localhost:11434")

        stub_request(:any, "http://new-unreachable-host.invalid:11434/").to_raise(Errno::ECONNREFUSED)

        provider.api_endpoint = "http://new-unreachable-host.invalid:11434"
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint].first).to include("connection refused")
      end

      it "skips reachability check when api_endpoint is not changed" do
        stub_request(:any, "http://localhost:11434/").to_return(status: 200)
        provider = create(:embedding_provider, :ollama, api_endpoint: "http://localhost:11434")

        # Change something else, not the endpoint
        provider.name = "Updated Name"

        # Should not try to connect again
        expect(provider).to be_valid
      end

      it "accepts endpoints that return error status codes" do
        stub_request(:any, "http://localhost:11434/").to_return(status: 404)

        provider = build(:embedding_provider, :ollama, api_endpoint: "http://localhost:11434")
        # Should be valid - we only care that we can connect, not the response status
        expect(provider).to be_valid
      end

      it "rejects URLs without host" do
        provider = build(:embedding_provider, :ollama, api_endpoint: "not-a-valid-url")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint].first).to include("not a valid URL")
      end

      it "rejects malformed URLs that fail to parse" do
        provider = build(:embedding_provider, :ollama, api_endpoint: "http://host with spaces")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint].first).to include("not a valid URL")
      end

      it "handles connection timeout" do
        stub_request(:any, "http://slow-host.example:11434/").to_timeout

        provider = build(:embedding_provider, :ollama, api_endpoint: "http://slow-host.example:11434")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint].first).to include("timed out")
      end

      it "handles host unreachable error" do
        stub_request(:any, "http://unreachable-host.example:11434/").to_raise(Errno::EHOSTUNREACH)

        provider = build(:embedding_provider, :ollama, api_endpoint: "http://unreachable-host.example:11434")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint].first).to include("host is unreachable")
      end

      it "handles network unreachable error" do
        stub_request(:any, "http://no-network.example:11434/").to_raise(Errno::ENETUNREACH)

        provider = build(:embedding_provider, :ollama, api_endpoint: "http://no-network.example:11434")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint].first).to include("network is unreachable")
      end

      it "handles SSL errors" do
        stub_request(:any, "https://bad-ssl.example:443/").to_raise(OpenSSL::SSL::SSLError.new("SSL_connect failed"))

        provider = build(:embedding_provider, :ollama, api_endpoint: "https://bad-ssl.example:443")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint].first).to include("SSL error")
      end

      it "handles generic connection errors" do
        stub_request(:any, "http://generic-error.example:11434/").to_raise(StandardError.new("Unexpected failure"))

        provider = build(:embedding_provider, :ollama, api_endpoint: "http://generic-error.example:11434")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint].first).to include("could not connect")
      end
    end
  end

  describe "encryption" do
    it "encrypts the api_key attribute" do
      provider = create(:embedding_provider, :openai)
      # Verify that api_key is encrypted by checking it's not stored as plain text
      expect(provider.api_key).to eq("sk-test-key-12345")

      # Verify the raw database value is encrypted (different from original)
      raw_value = EmbeddingProvider.connection.select_value(
        "SELECT api_key FROM embedding_providers WHERE id = #{provider.id}"
      )
      expect(raw_value).not_to eq("sk-test-key-12345")
    end
  end

  describe "scopes" do
    describe ".enabled" do
      it "returns only enabled providers" do
        enabled = create(:embedding_provider, :enabled)
        _disabled = create(:embedding_provider, enabled: false)

        expect(described_class.enabled).to contain_exactly(enabled)
      end
    end
  end

  describe "#display_provider_type" do
    it "returns formatted provider type names" do
      expect(build(:embedding_provider, provider_type: "openai").display_provider_type).to eq("OpenAI")
      expect(build(:embedding_provider, provider_type: "cohere").display_provider_type).to eq("Cohere")
      expect(build(:embedding_provider, provider_type: "ollama").display_provider_type).to eq("Ollama (Self-hosted)")
      expect(build(:embedding_provider, provider_type: "azure_openai").display_provider_type).to eq("Azure OpenAI")
      expect(build(:embedding_provider, provider_type: "bedrock").display_provider_type).to eq("AWS Bedrock")
      expect(build(:embedding_provider, provider_type: "huggingface").display_provider_type).to eq("Hugging Face")
    end

    it "returns 'Not Selected' when provider_type is nil or empty" do
      provider = EmbeddingProvider.new
      expect(provider.display_provider_type).to eq("Not Selected")

      provider.provider_type = ""
      expect(provider.display_provider_type).to eq("Not Selected")
    end

    it "titleizes unknown provider types" do
      provider = build(:embedding_provider, provider_type: "custom_provider")
      expect(provider.display_provider_type).to eq("Custom Provider")
    end
  end

  describe "#requires_api_key?" do
    it "returns true for cloud providers" do
      expect(build(:embedding_provider, provider_type: "openai").requires_api_key?).to be true
      expect(build(:embedding_provider, provider_type: "cohere").requires_api_key?).to be true
      expect(build(:embedding_provider, provider_type: "azure_openai").requires_api_key?).to be true
      expect(build(:embedding_provider, provider_type: "bedrock").requires_api_key?).to be true
      expect(build(:embedding_provider, provider_type: "huggingface").requires_api_key?).to be true
    end

    it "returns false for self-hosted providers" do
      expect(build(:embedding_provider, provider_type: "ollama").requires_api_key?).to be false
    end
  end

  describe "#requires_api_endpoint?" do
    it "returns true for providers that need custom endpoints" do
      expect(build(:embedding_provider, provider_type: "ollama").requires_api_endpoint?).to be true
      expect(build(:embedding_provider, provider_type: "azure_openai").requires_api_endpoint?).to be true
    end

    it "returns false for providers with default endpoints" do
      expect(build(:embedding_provider, provider_type: "openai").requires_api_endpoint?).to be false
      expect(build(:embedding_provider, provider_type: "cohere").requires_api_endpoint?).to be false
    end
  end

  describe ".default_config_for" do
    it "returns default configuration for OpenAI" do
      config = described_class.default_config_for("openai")
      expect(config[:embedding_model]).to eq("text-embedding-3-large")
      expect(config[:dimensions]).to eq(3072)
    end

    it "returns default configuration for Cohere" do
      config = described_class.default_config_for("cohere")
      expect(config[:embedding_model]).to eq("embed-v4.0")
      expect(config[:dimensions]).to eq(1536)
    end

    it "returns default configuration for Ollama" do
      config = described_class.default_config_for("ollama")
      expect(config[:embedding_model]).to eq("nomic-embed-text")
      expect(config[:dimensions]).to eq(768)
    end
  end

  describe "#can_delete?" do
    it "returns true for disabled providers" do
      provider = build(:embedding_provider, enabled: false)
      expect(provider.can_delete?).to be true
    end

    it "returns false for enabled providers" do
      provider = build(:embedding_provider, enabled: true)
      expect(provider.can_delete?).to be false
    end
  end

  describe "#available_models" do
    it "returns models for the provider type" do
      provider = build(:embedding_provider, provider_type: "openai")
      expect(provider.available_models).to include("text-embedding-3-small" => 1536)
    end
  end

  describe "enable_if_first callback" do
    it "auto-enables the first provider created" do
      provider = create(:embedding_provider, :openai, enabled: false)
      expect(provider.reload.enabled).to be true
    end

    it "does not auto-enable subsequent providers" do
      create(:embedding_provider, :openai) # First one
      second = create(:embedding_provider, :cohere, enabled: false)
      expect(second.reload.enabled).to be false
    end
  end

  describe "#similarity_threshold" do
    it "returns the default threshold for the model" do
      # OpenAI text-embedding-3-small has threshold 0.28
      provider = build(:embedding_provider, provider_type: "openai", embedding_model: "text-embedding-3-small")
      expect(provider.similarity_threshold).to eq(0.28)

      # Ollama nomic-embed-text has threshold 0.42
      provider = build(:embedding_provider, :ollama, embedding_model: "nomic-embed-text")
      expect(provider.similarity_threshold).to eq(0.42)
    end

    it "returns a custom threshold when set in settings" do
      provider = build(:embedding_provider, provider_type: "openai")
      provider.similarity_threshold = 0.5
      expect(provider.similarity_threshold).to eq(0.5)
    end

    it "persists the threshold in the settings jsonb column" do
      provider = create(:embedding_provider, :openai)
      provider.similarity_threshold = 0.45
      provider.save!

      provider.reload
      expect(provider.similarity_threshold).to eq(0.45)
      expect(provider.settings["similarity_threshold"]).to eq(0.45)
    end
  end

  describe "#default_similarity_threshold" do
    it "returns model-specific defaults when model is known" do
      # Model-specific thresholds take precedence
      expect(build(:embedding_provider, provider_type: "openai", embedding_model: "text-embedding-3-small").default_similarity_threshold).to eq(0.28)
      expect(build(:embedding_provider, provider_type: "cohere", embedding_model: "embed-english-v3.0").default_similarity_threshold).to eq(0.30)
      expect(build(:embedding_provider, :ollama, embedding_model: "nomic-embed-text").default_similarity_threshold).to eq(0.42)
      expect(build(:embedding_provider, provider_type: "huggingface", embedding_model: "sentence-transformers/all-MiniLM-L6-v2").default_similarity_threshold).to eq(0.30)
    end

    it "falls back to provider-type threshold for unknown models" do
      # Unknown model falls back to provider type threshold
      provider = build(:embedding_provider, provider_type: "openai", embedding_model: "unknown-model")
      allow(provider).to receive(:embedding_model).and_return("unknown-model")
      expect(provider.default_similarity_threshold).to eq(0.28) # OpenAI provider fallback
    end

    it "falls back to 0.3 for unknown provider types and unknown models" do
      provider = build(:embedding_provider, provider_type: "openai")
      # Simulate unknown type and model
      allow(provider).to receive(:provider_type).and_return("unknown")
      allow(provider).to receive(:embedding_model).and_return("unknown-model")
      expect(provider.default_similarity_threshold).to eq(0.3)
    end
  end

  describe "#chunk_size" do
    it "returns the default chunk size when not set" do
      provider = build(:embedding_provider, :openai)
      expect(provider.chunk_size).to eq(EmbeddingProvider::DEFAULT_CHUNK_SIZE)
    end

    it "returns a custom chunk size when set in settings" do
      provider = build(:embedding_provider, :openai)
      provider.chunk_size = 256
      expect(provider.chunk_size).to eq(256)
    end

    it "persists the chunk size in the settings jsonb column" do
      provider = create(:embedding_provider, :openai)
      provider.chunk_size = 1024
      provider.save!

      provider.reload
      expect(provider.chunk_size).to eq(1024)
      expect(provider.settings["chunk_size"]).to eq(1024)
    end
  end

  describe "#chunk_overlap" do
    it "returns the default chunk overlap when not set" do
      provider = build(:embedding_provider, :openai)
      expect(provider.chunk_overlap).to eq(EmbeddingProvider::DEFAULT_CHUNK_OVERLAP)
    end

    it "returns a custom chunk overlap when set in settings" do
      provider = build(:embedding_provider, :openai)
      provider.chunk_overlap = 20
      expect(provider.chunk_overlap).to eq(20)
    end

    it "clamps chunk overlap to 0-50 range" do
      provider = build(:embedding_provider, :openai)

      provider.chunk_overlap = -5
      expect(provider.chunk_overlap).to eq(0)

      provider.chunk_overlap = 75
      expect(provider.chunk_overlap).to eq(50)
    end

    it "persists the chunk overlap in the settings jsonb column" do
      provider = create(:embedding_provider, :openai)
      provider.chunk_overlap = 15
      provider.save!

      provider.reload
      expect(provider.chunk_overlap).to eq(15)
      expect(provider.settings["chunk_overlap"]).to eq(15)
    end
  end

  describe "#chunk_overlap_tokens" do
    it "calculates overlap in tokens based on chunk_size and chunk_overlap percentage" do
      provider = build(:embedding_provider, :openai)
      provider.chunk_size = 500
      provider.chunk_overlap = 10

      expect(provider.chunk_overlap_tokens).to eq(50)
    end

    it "rounds to nearest integer" do
      provider = build(:embedding_provider, :openai)
      provider.chunk_size = 512
      provider.chunk_overlap = 15  # 15% of 512 = 76.8

      expect(provider.chunk_overlap_tokens).to eq(77)
    end
  end

  describe "#chunk_size_chars" do
    it "returns chunk size in characters" do
      provider = build(:embedding_provider, :openai)
      provider.chunk_size = 512

      expect(provider.chunk_size_chars).to eq(512 * EmbeddingProvider::CHARS_PER_TOKEN)
    end
  end
end
