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
      expect(config[:embedding_model]).to eq("text-embedding-3-small")
      expect(config[:dimensions]).to eq(1536)
    end

    it "returns default configuration for Cohere" do
      config = described_class.default_config_for("cohere")
      expect(config[:embedding_model]).to eq("embed-english-v3.0")
      expect(config[:dimensions]).to eq(1024)
    end

    it "returns default configuration for Ollama" do
      config = described_class.default_config_for("ollama")
      expect(config[:embedding_model]).to eq("embeddinggemma")
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

      # Ollama embeddinggemma has threshold 0.38
      provider = build(:embedding_provider, :ollama, embedding_model: "embeddinggemma")
      expect(provider.similarity_threshold).to eq(0.38)
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
      expect(build(:embedding_provider, :ollama, embedding_model: "embeddinggemma").default_similarity_threshold).to eq(0.38)
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
end
