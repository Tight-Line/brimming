# frozen_string_literal: true

require "rails_helper"

RSpec.describe LlmService do
  describe ".available?" do
    it "returns true when an enabled provider exists" do
      create(:llm_provider, :enabled)
      expect(described_class.available?).to be true
    end

    it "returns false when no providers are enabled" do
      create(:llm_provider, :enabled)
      create(:llm_provider, enabled: false)
      LlmProvider.where(enabled: true).delete_all

      expect(described_class.available?).to be false
    end
  end

  describe ".default_provider" do
    it "returns the default provider" do
      _regular = create(:llm_provider, :enabled)
      default_provider = create(:llm_provider, :default)

      expect(described_class.default_provider).to eq(default_provider)
    end
  end

  describe ".client" do
    let(:mock_context) { instance_double("RubyLLM::Context") }

    before do
      allow(RubyLLM).to receive(:context).and_return(mock_context)
    end

    it "creates a new client instance" do
      create(:llm_provider, :enabled)
      expect(described_class.client).to be_a(LlmService::Client)
    end

    it "accepts a specific provider" do
      provider = create(:llm_provider, :enabled)
      client = described_class.client(provider)
      expect(client.provider).to eq(provider)
    end
  end
end

RSpec.describe LlmService::Client do
  let(:mock_context) { instance_double("RubyLLM::Context") }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }

  before do
    allow(RubyLLM).to receive(:context).and_return(mock_context)
  end

  describe "#initialize" do
    it "uses the default provider if none specified" do
      provider = create(:llm_provider, :default)
      client = described_class.new

      expect(client.provider).to eq(provider)
    end

    it "uses the specified provider" do
      _default = create(:llm_provider, :default)
      other = create(:llm_provider, :enabled)
      client = described_class.new(other)

      expect(client.provider).to eq(other)
    end

    context "when no provider is available" do
      it "raises NoProviderError" do
        expect { described_class.new }.to raise_error(
          LlmService::Client::NoProviderError,
          "No LLM provider configured or enabled"
        )
      end
    end

    context "when provider has no model" do
      it "raises ConfigurationError" do
        provider = build(:llm_provider, provider_type: "openai", llm_model: "", api_key: "sk-test")
        allow(LlmProvider).to receive(:default_provider).and_return(provider)

        expect { described_class.new }.to raise_error(
          LlmService::Client::ConfigurationError,
          "Provider must have a model name"
        )
      end
    end

    context "when OpenAI provider has no API key" do
      it "raises ConfigurationError" do
        provider = build(:llm_provider, provider_type: "openai", llm_model: "gpt-4o", api_key: nil)
        allow(LlmProvider).to receive(:default_provider).and_return(provider)

        expect { described_class.new }.to raise_error(
          LlmService::Client::ConfigurationError,
          "Openai adapter requires an API key"
        )
      end
    end

    context "when Anthropic provider has no API key" do
      it "raises ConfigurationError" do
        provider = build(:llm_provider, provider_type: "anthropic", llm_model: "claude-3-sonnet", api_key: nil)
        allow(LlmProvider).to receive(:default_provider).and_return(provider)

        expect { described_class.new }.to raise_error(
          LlmService::Client::ConfigurationError,
          "Anthropic adapter requires an API key"
        )
      end
    end

    it "builds a context on initialization" do
      create(:llm_provider, :openai, :default)

      expect(RubyLLM).to receive(:context).and_return(mock_context)
      described_class.new
    end
  end

  describe "#complete" do
    let!(:provider) { create(:llm_provider, :openai, :default) }
    let(:client) { described_class.new }
    let(:mock_response) { double(content: "Hello!") }

    before do
      allow(mock_context).to receive(:chat).and_return(mock_chat)
      allow(mock_chat).to receive(:ask).and_return(mock_response)
    end

    it "sends a single message chat request" do
      result = client.complete("Say hello")
      expect(result).to eq("Hello!")
    end

    it "calls context.chat with correct options" do
      expect(mock_context).to receive(:chat).with(
        hash_including(model: "gpt-4o", assume_model_exists: true, provider: :openai)
      ).and_return(mock_chat)

      client.complete("Say hello")
    end
  end

  describe "#chat" do
    let!(:provider) { create(:llm_provider, :openai, :default) }
    let(:client) { described_class.new }
    let(:mock_response) { double(content: "I'm doing well!") }

    before do
      allow(mock_context).to receive(:chat).and_return(mock_chat)
    end

    context "with a single message" do
      it "sends the message to ruby_llm" do
        allow(mock_chat).to receive(:ask).with("How are you?").and_return(mock_response)

        messages = [ { role: "user", content: "How are you?" } ]
        result = client.chat(messages)
        expect(result).to eq("I'm doing well!")
      end
    end

    context "with multiple messages including system" do
      it "sets system instructions and sends user messages" do
        allow(mock_chat).to receive(:with_instructions).with("You are a helpful assistant")
        allow(mock_chat).to receive(:ask).with("Hello").and_return(double(content: "Hello, human!"))

        messages = [
          { role: "system", content: "You are a helpful assistant" },
          { role: "user", content: "Hello" }
        ]
        result = client.chat(messages)
        expect(result).to eq("Hello, human!")
      end

      it "calls with_instructions for system message" do
        expect(mock_chat).to receive(:with_instructions).with("Be brief")
        allow(mock_chat).to receive(:ask).and_return(mock_response)

        messages = [
          { role: "system", content: "Be brief" },
          { role: "user", content: "Hi" }
        ]
        client.chat(messages)
      end
    end

    context "with multiple user messages (no system message)" do
      it "sends user messages without calling with_instructions" do
        expect(mock_chat).not_to receive(:with_instructions)
        allow(mock_chat).to receive(:ask).with("First").and_return(double(content: "Response 1"))
        allow(mock_chat).to receive(:ask).with("Second").and_return(mock_response)

        messages = [
          { role: "user", content: "First" },
          { role: "user", content: "Second" }
        ]
        result = client.chat(messages)
        expect(result).to eq("I'm doing well!")
      end
    end

    context "with assistant messages in history" do
      it "skips assistant messages and only sends user messages" do
        allow(mock_chat).to receive(:ask).with("Hello").and_return(double(content: "Hi there!"))
        allow(mock_chat).to receive(:ask).with("Goodbye").and_return(mock_response)

        messages = [
          { role: "user", content: "Hello" },
          { role: "assistant", content: "Hi there!" },
          { role: "user", content: "Goodbye" }
        ]
        result = client.chat(messages)
        expect(result).to eq("I'm doing well!")
      end
    end

    context "when ruby_llm raises an error" do
      # RubyLLM::Error expects a response object, so we create a mock error class for testing
      let(:ruby_llm_error_class) do
        Class.new(StandardError) do
          def initialize(msg)
            super(msg)
          end
        end
      end

      before do
        allow(mock_context).to receive(:chat).and_return(mock_chat)
        # Stub the RubyLLM::Error constant to use our simple test class
        stub_const("RubyLLM::Error", ruby_llm_error_class)
      end

      it "converts rate limit errors" do
        allow(mock_chat).to receive(:ask).and_raise(RubyLLM::Error.new("Rate limit exceeded (429)"))

        messages = [ { role: "user", content: "Hello" } ]
        expect { client.chat(messages) }.to raise_error(
          LlmService::Client::ApiError,
          /Rate limit exceeded/
        )
      end

      it "converts invalid key errors" do
        allow(mock_chat).to receive(:ask).and_raise(RubyLLM::Error.new("Invalid API key"))

        messages = [ { role: "user", content: "Hello" } ]
        expect { client.chat(messages) }.to raise_error(
          LlmService::Client::ConfigurationError,
          /Invalid API key/
        )
      end

      it "converts not found errors" do
        allow(mock_chat).to receive(:ask).and_raise(RubyLLM::Error.new("Model not found"))

        messages = [ { role: "user", content: "Hello" } ]
        expect { client.chat(messages) }.to raise_error(
          LlmService::Client::ConfigurationError,
          /Model not found/
        )
      end

      it "converts other errors to ApiError" do
        allow(mock_chat).to receive(:ask).and_raise(RubyLLM::Error.new("Unknown error"))

        messages = [ { role: "user", content: "Hello" } ]
        expect { client.chat(messages) }.to raise_error(
          LlmService::Client::ApiError,
          /LLM error: Unknown error/
        )
      end
    end
  end

  describe "#generate_json" do
    let!(:provider) { create(:llm_provider, :openai, :default) }
    let(:client) { described_class.new }

    before do
      allow(mock_context).to receive(:chat).and_return(mock_chat)
    end

    it "returns parsed JSON from response" do
      allow(mock_chat).to receive(:ask).and_return(double(content: '{"name": "test"}'))

      result = client.generate_json("Generate a name")
      expect(result).to eq({ "name" => "test" })
    end

    it "handles JSON in markdown code blocks" do
      allow(mock_chat).to receive(:ask).and_return(double(content: "```json\n{\"name\": \"test\"}\n```"))

      result = client.generate_json("Generate a name")
      expect(result).to eq({ "name" => "test" })
    end

    it "raises ApiError on invalid JSON" do
      allow(mock_chat).to receive(:ask).and_return(double(content: "not valid json"))

      expect { client.generate_json("Generate") }.to raise_error(
        LlmService::Client::ApiError,
        /Failed to parse JSON/
      )
    end

    it "includes schema in the prompt when provided" do
      schema = { type: "object", properties: { name: { type: "string" } } }

      allow(mock_chat).to receive(:ask) do |prompt|
        expect(prompt).to include("JSON should follow this schema")
        expect(prompt).to include("type")
        double(content: '{"name": "test"}')
      end

      client.generate_json("Generate a name", schema: schema)
    end
  end

  describe "provider configuration" do
    describe "OpenAI provider" do
      it "configures openai_api_key in context" do
        provider = create(:llm_provider, :openai, :default, api_key: "sk-test-key")

        expect(RubyLLM).to receive(:context) do |&block|
          config = double("RubyLLM::Configuration")
          expect(config).to receive(:request_timeout=).with(120)
          expect(config).to receive(:openai_api_key=).with("sk-test-key")
          block.call(config)
          mock_context
        end

        described_class.new
      end

      it "configures custom endpoint when provided" do
        stub_request(:head, "https://custom.openai.com/v1").to_return(status: 200)
        provider = create(:llm_provider, :openai, :default, api_endpoint: "https://custom.openai.com/v1")

        expect(RubyLLM).to receive(:context) do |&block|
          config = double("RubyLLM::Configuration")
          expect(config).to receive(:request_timeout=).with(120)
          expect(config).to receive(:openai_api_key=)
          expect(config).to receive(:openai_api_base=).with("https://custom.openai.com/v1")
          block.call(config)
          mock_context
        end

        described_class.new
      end
    end

    describe "Anthropic provider" do
      it "configures anthropic_api_key in context" do
        provider = create(:llm_provider, :anthropic, :default)

        expect(RubyLLM).to receive(:context) do |&block|
          config = double("RubyLLM::Configuration")
          expect(config).to receive(:request_timeout=).with(120)
          expect(config).to receive(:anthropic_api_key=).with(provider.api_key)
          block.call(config)
          mock_context
        end

        described_class.new
      end
    end

    describe "Ollama provider" do
      before do
        stub_request(:head, /localhost:11434/).to_return(status: 200)
      end

      it "configures ollama_api_base with /v1 suffix" do
        provider = create(:llm_provider, :ollama, :default, api_endpoint: "http://localhost:11434")

        expect(RubyLLM).to receive(:context) do |&block|
          config = double("RubyLLM::Configuration")
          expect(config).to receive(:request_timeout=).with(120)
          expect(config).to receive(:ollama_api_base=).with("http://localhost:11434/v1")
          block.call(config)
          mock_context
        end

        described_class.new
      end

      it "preserves /v1 suffix if already present" do
        provider = create(:llm_provider, :ollama, :default, api_endpoint: "http://localhost:11434/v1")

        expect(RubyLLM).to receive(:context) do |&block|
          config = double("RubyLLM::Configuration")
          expect(config).to receive(:request_timeout=).with(120)
          expect(config).to receive(:ollama_api_base=).with("http://localhost:11434/v1")
          block.call(config)
          mock_context
        end

        described_class.new
      end

      it "uses default endpoint when not specified" do
        provider = create(:llm_provider, :ollama, :default, api_endpoint: nil)

        expect(RubyLLM).to receive(:context) do |&block|
          config = double("RubyLLM::Configuration")
          expect(config).to receive(:request_timeout=).with(120)
          expect(config).to receive(:ollama_api_base=).with("http://localhost:11434/v1")
          block.call(config)
          mock_context
        end

        described_class.new
      end
    end

    describe "Azure OpenAI provider" do
      it "configures openai credentials with custom endpoint" do
        stub_request(:head, "https://myinstance.openai.azure.com/").to_return(status: 200)
        provider = build(:llm_provider,
          provider_type: "azure_openai",
          llm_model: "gpt-4",
          api_key: "azure-key",
          api_endpoint: "https://myinstance.openai.azure.com/",
          enabled: true,
          is_default: true)
        allow(LlmProvider).to receive(:default_provider).and_return(provider)

        expect(RubyLLM).to receive(:context) do |&block|
          config = double("RubyLLM::Configuration")
          expect(config).to receive(:request_timeout=).with(120)
          expect(config).to receive(:openai_api_key=).with("azure-key")
          expect(config).to receive(:openai_api_base=).with("https://myinstance.openai.azure.com/")
          block.call(config)
          mock_context
        end

        described_class.new
      end
    end

    describe "Bedrock provider" do
      it "configures bedrock credentials" do
        provider = build(:llm_provider,
          provider_type: "bedrock",
          llm_model: "anthropic.claude-3-sonnet",
          api_key: "bedrock-key",
          settings: { "secret_key" => "secret", "region" => "us-west-2" },
          enabled: true,
          is_default: true)
        allow(LlmProvider).to receive(:default_provider).and_return(provider)

        expect(RubyLLM).to receive(:context) do |&block|
          config = double("RubyLLM::Configuration")
          expect(config).to receive(:request_timeout=).with(120)
          expect(config).to receive(:bedrock_api_key=).with("bedrock-key")
          expect(config).to receive(:bedrock_secret_key=).with("secret")
          expect(config).to receive(:bedrock_region=).with("us-west-2")
          block.call(config)
          mock_context
        end

        described_class.new
      end

      it "uses default region when not specified" do
        provider = build(:llm_provider,
          provider_type: "bedrock",
          llm_model: "anthropic.claude-3-sonnet",
          api_key: "bedrock-key",
          settings: {},
          enabled: true,
          is_default: true)
        allow(LlmProvider).to receive(:default_provider).and_return(provider)

        expect(RubyLLM).to receive(:context) do |&block|
          config = double("RubyLLM::Configuration")
          expect(config).to receive(:request_timeout=).with(120)
          expect(config).to receive(:bedrock_api_key=)
          expect(config).to receive(:bedrock_secret_key=)
          expect(config).to receive(:bedrock_region=).with("us-east-1")
          block.call(config)
          mock_context
        end

        described_class.new
      end

      it "raises error when API key missing" do
        provider = build(:llm_provider,
          provider_type: "bedrock",
          llm_model: "anthropic.claude-3-sonnet",
          api_key: nil,
          enabled: true,
          is_default: true)
        allow(LlmProvider).to receive(:default_provider).and_return(provider)

        expect { described_class.new }.to raise_error(
          LlmService::Client::ConfigurationError,
          "Bedrock adapter requires API key and secret"
        )
      end
    end

    describe "Cohere provider" do
      it "configures openai credentials with custom endpoint" do
        stub_request(:head, "https://api.cohere.ai/v1/").to_return(status: 200)
        provider = build(:llm_provider,
          provider_type: "cohere",
          llm_model: "command-r-plus",
          api_key: "cohere-key",
          api_endpoint: "https://api.cohere.ai/v1/",
          enabled: true,
          is_default: true)
        allow(LlmProvider).to receive(:default_provider).and_return(provider)

        expect(RubyLLM).to receive(:context) do |&block|
          config = double("RubyLLM::Configuration")
          expect(config).to receive(:request_timeout=).with(120)
          expect(config).to receive(:openai_api_key=).with("cohere-key")
          expect(config).to receive(:openai_api_base=).with("https://api.cohere.ai/v1/")
          block.call(config)
          mock_context
        end

        described_class.new
      end

      it "raises error when API key missing" do
        provider = build(:llm_provider,
          provider_type: "cohere",
          llm_model: "command-r-plus",
          api_key: nil,
          enabled: true,
          is_default: true)
        allow(LlmProvider).to receive(:default_provider).and_return(provider)

        expect { described_class.new }.to raise_error(
          LlmService::Client::ConfigurationError,
          "Cohere adapter requires an API key"
        )
      end
    end
  end

  describe "response handling" do
    let!(:provider) { create(:llm_provider, :openai, :default) }
    let(:client) { described_class.new }

    before do
      allow(mock_context).to receive(:chat).and_return(mock_chat)
    end

    it "handles nil response" do
      allow(mock_chat).to receive(:ask).and_return(nil)

      result = client.complete("test")
      expect(result).to eq("")
    end

    it "handles response without content method" do
      allow(mock_chat).to receive(:ask).and_return("plain string response")

      result = client.complete("test")
      expect(result).to eq("plain string response")
    end
  end
end
