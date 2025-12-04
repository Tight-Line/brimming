# frozen_string_literal: true

require "rails_helper"

RSpec.describe LlmProvider do
  describe "validations" do
    subject { build(:llm_provider) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:provider_type) }
    it { is_expected.to validate_inclusion_of(:provider_type).in_array(LlmProvider::PROVIDER_TYPES) }
    it { is_expected.to validate_presence_of(:llm_model) }

    it "validates api_endpoint is required for ollama" do
      # Build without ollama trait to avoid the default endpoint
      provider = build(:llm_provider, provider_type: "ollama", api_endpoint: nil)
      # Clear the default that gets set in before_validation
      provider.instance_variable_set(:@skip_endpoint_check, true)

      # Manually call the validation
      provider.send(:api_endpoint_required_for_provider)
      expect(provider.errors[:api_endpoint]).to include("is required for Ollama (Self-hosted)")
    end

    it "validates api_endpoint is required for azure_openai" do
      provider = build(:llm_provider, provider_type: "azure_openai", api_key: "test", api_endpoint: "")
      expect(provider).not_to be_valid
      expect(provider.errors[:api_endpoint]).to include("is required for Azure OpenAI")
    end

    describe "api_endpoint reachability" do
      it "validates endpoint is reachable when creating with api_endpoint" do
        stub_request(:any, "http://unreachable-host.invalid:11434/").to_raise(SocketError.new("getaddrinfo: nodename nor servname provided"))

        provider = build(:llm_provider, :ollama, api_endpoint: "http://unreachable-host.invalid:11434")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint].first).to include("could not resolve host")
      end

      it "skips reachability check when api_endpoint is not changed" do
        stub_request(:any, "http://localhost:11434/").to_return(status: 200)
        provider = create(:llm_provider, :ollama, api_endpoint: "http://localhost:11434")

        provider.name = "Updated Name"
        expect(provider).to be_valid
      end

      it "adds error for URL without host" do
        provider = build(:llm_provider, :ollama, api_endpoint: "http:///no-host")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint]).to include("is not a valid URL")
      end

      it "adds error for malformed URI" do
        provider = build(:llm_provider, :ollama)
        # Force a URI::InvalidURIError by stubbing URI.parse
        allow(URI).to receive(:parse).and_raise(URI::InvalidURIError.new("bad URI"))
        provider.api_endpoint = "http://localhost:11434"
        provider.valid?
        expect(provider.errors[:api_endpoint]).to include("is not a valid URL")
      end

      it "adds error when connection is refused" do
        stub_request(:any, "http://localhost:11434/").to_raise(Errno::ECONNREFUSED)

        provider = build(:llm_provider, :ollama, api_endpoint: "http://localhost:11434")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint]).to include("connection refused - is the service running?")
      end

      it "adds error when host is unreachable" do
        stub_request(:any, "http://localhost:11434/").to_raise(Errno::EHOSTUNREACH)

        provider = build(:llm_provider, :ollama, api_endpoint: "http://localhost:11434")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint]).to include("host is unreachable")
      end

      it "adds error when network is unreachable" do
        stub_request(:any, "http://localhost:11434/").to_raise(Errno::ENETUNREACH)

        provider = build(:llm_provider, :ollama, api_endpoint: "http://localhost:11434")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint]).to include("network is unreachable")
      end

      it "adds error when connection times out" do
        stub_request(:any, "http://localhost:11434/").to_raise(Net::OpenTimeout)

        provider = build(:llm_provider, :ollama, api_endpoint: "http://localhost:11434")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint]).to include("connection timed out")
      end

      it "adds error for SSL errors" do
        stub_request(:any, "https://localhost:11434/").to_raise(OpenSSL::SSL::SSLError.new("SSL_connect returned=1 errno=0"))

        provider = build(:llm_provider, :ollama, api_endpoint: "https://localhost:11434")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint].first).to include("SSL error")
      end

      it "adds error for other connection errors" do
        stub_request(:any, "http://localhost:11434/").to_raise(StandardError.new("unexpected error"))

        provider = build(:llm_provider, :ollama, api_endpoint: "http://localhost:11434")
        expect(provider).not_to be_valid
        expect(provider.errors[:api_endpoint].first).to include("could not connect")
      end
    end
  end

  describe "scopes" do
    describe ".enabled" do
      it "returns only enabled providers" do
        enabled = create(:llm_provider, :enabled)
        _disabled = create(:llm_provider, enabled: false)

        expect(LlmProvider.enabled).to eq([ enabled ])
      end
    end

    describe ".by_default" do
      it "returns the default provider" do
        _regular = create(:llm_provider, :enabled)
        default_provider = create(:llm_provider, :default)

        expect(LlmProvider.by_default).to eq([ default_provider ])
      end
    end
  end

  describe ".default_provider" do
    it "returns the default provider if one exists" do
      _regular = create(:llm_provider, :enabled)
      default_provider = create(:llm_provider, :default)

      expect(LlmProvider.default_provider).to eq(default_provider)
    end

    it "falls back to first enabled provider if no default" do
      first_enabled = create(:llm_provider, :enabled)
      _second_enabled = create(:llm_provider, :enabled)

      expect(LlmProvider.default_provider).to eq(first_enabled)
    end

    it "returns nil if no providers enabled" do
      # Need a pre-existing provider so the new one doesn't auto-enable
      create(:llm_provider, :enabled)
      disabled = create(:llm_provider, enabled: false)
      LlmProvider.where(enabled: true).delete_all

      expect(LlmProvider.default_provider).to be_nil
    end
  end

  describe ".available?" do
    it "returns true when an enabled provider exists" do
      create(:llm_provider, :enabled)
      expect(LlmProvider.available?).to be true
    end

    it "returns false when no providers are enabled" do
      # Need a pre-existing provider so the new one doesn't auto-enable
      create(:llm_provider, :enabled)
      create(:llm_provider, enabled: false)
      LlmProvider.where(enabled: true).delete_all

      expect(LlmProvider.available?).to be false
    end
  end

  describe "#display_provider_type" do
    it "returns human-readable provider names" do
      expect(build(:llm_provider, provider_type: "openai").display_provider_type).to eq("OpenAI")
      expect(build(:llm_provider, provider_type: "anthropic").display_provider_type).to eq("Anthropic")
      expect(build(:llm_provider, provider_type: "ollama").display_provider_type).to eq("Ollama (Self-hosted)")
      expect(build(:llm_provider, provider_type: "azure_openai").display_provider_type).to eq("Azure OpenAI")
      expect(build(:llm_provider, provider_type: "bedrock").display_provider_type).to eq("AWS Bedrock")
      expect(build(:llm_provider, provider_type: "cohere").display_provider_type).to eq("Cohere")
    end
  end

  describe "#requires_api_key?" do
    it "returns true for cloud providers" do
      expect(build(:llm_provider, provider_type: "openai").requires_api_key?).to be true
      expect(build(:llm_provider, provider_type: "anthropic").requires_api_key?).to be true
      expect(build(:llm_provider, provider_type: "cohere").requires_api_key?).to be true
    end

    it "returns false for self-hosted providers" do
      expect(build(:llm_provider, provider_type: "ollama").requires_api_key?).to be false
    end
  end

  describe "#can_delete?" do
    it "returns true when not enabled" do
      provider = build(:llm_provider, enabled: false)
      expect(provider.can_delete?).to be true
    end

    it "returns false when enabled" do
      provider = build(:llm_provider, enabled: true)
      expect(provider.can_delete?).to be false
    end
  end

  describe "settings accessors" do
    describe "#temperature" do
      it "returns the stored temperature" do
        provider = build(:llm_provider)
        provider.temperature = 0.5
        expect(provider.temperature).to eq(0.5)
      end

      it "returns default when not set" do
        provider = build(:llm_provider, settings: {})
        expect(provider.temperature).to eq(0.7)
      end

      it "clamps values to valid range" do
        provider = build(:llm_provider)
        provider.temperature = 3.0
        expect(provider.temperature).to eq(2.0)

        provider.temperature = -1.0
        expect(provider.temperature).to eq(0.0)
      end
    end

    describe "#max_tokens" do
      it "returns the stored max_tokens" do
        provider = build(:llm_provider)
        provider.max_tokens = 4096
        expect(provider.max_tokens).to eq(4096)
      end

      it "returns default when not set" do
        provider = build(:llm_provider, settings: {})
        expect(provider.max_tokens).to eq(2048)
      end
    end
  end

  describe "callbacks" do
    describe "#ensure_single_default" do
      it "removes default from other providers when setting a new default" do
        first = create(:llm_provider, :default)
        second = create(:llm_provider, :enabled)

        second.update!(is_default: true)

        expect(first.reload.is_default?).to be false
        expect(second.reload.is_default?).to be true
      end

      it "does nothing when provider is set to not default" do
        first = create(:llm_provider, :default)
        second = create(:llm_provider, :enabled)

        # Set second as default first
        second.update!(is_default: true)
        expect(first.reload.is_default?).to be false
        expect(second.reload.is_default?).to be true

        # Now set second back to not default - this exercises the early return
        second.update!(is_default: false)

        # Neither should be default now
        expect(first.reload.is_default?).to be false
        expect(second.reload.is_default?).to be false
      end
    end

    describe "#set_as_default_if_first" do
      it "automatically enables and sets first provider as default" do
        provider = create(:llm_provider, enabled: false, is_default: false)

        expect(provider.reload.enabled?).to be true
        expect(provider.reload.is_default?).to be true
      end

      it "does not auto-set subsequent providers" do
        create(:llm_provider)
        second = create(:llm_provider, enabled: false, is_default: false)

        expect(second.reload.enabled?).to be false
        expect(second.reload.is_default?).to be false
      end
    end
  end

  describe ".models_for" do
    it "returns available models for a provider type" do
      models = LlmProvider.models_for("openai")
      expect(models).to include("gpt-4o", "gpt-4o-mini")
    end

    it "returns empty array for unknown provider" do
      expect(LlmProvider.models_for("unknown")).to eq([])
    end

    it "returns empty array for ollama (dynamic discovery)" do
      expect(LlmProvider.models_for("ollama")).to eq([])
    end
  end

  describe "#uses_dynamic_models?" do
    it "returns true for ollama" do
      expect(build(:llm_provider, provider_type: "ollama").uses_dynamic_models?).to be true
    end

    it "returns false for other providers" do
      expect(build(:llm_provider, provider_type: "openai").uses_dynamic_models?).to be false
      expect(build(:llm_provider, provider_type: "anthropic").uses_dynamic_models?).to be false
      expect(build(:llm_provider, provider_type: "azure_openai").uses_dynamic_models?).to be false
    end
  end
end
