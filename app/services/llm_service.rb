# frozen_string_literal: true

require "ruby_llm"

# Namespace module for LLM service components
module LlmService
  # Main service for generating text completions using configured providers
  #
  # Usage:
  #   service = LlmService::Client.new
  #   response = service.complete("Generate a question about Ruby on Rails")
  #   response = service.chat([{ role: "user", content: "Hello" }])
  #
  # Or with a specific provider:
  #   provider = LlmProvider.find(1)
  #   service = LlmService::Client.new(provider)
  #
  class Client
    class Error < StandardError; end
    class NoProviderError < Error; end
    class ConfigurationError < Error; end
    class ApiError < Error; end

    # Map our provider_type to ruby_llm provider symbols
    # Must match LlmProvider::PROVIDER_TYPES
    PROVIDER_MAP = {
      "openai" => :openai,
      "anthropic" => :anthropic,
      "ollama" => :ollama,
      "azure_openai" => :openai,  # Azure uses OpenAI-compatible API
      "bedrock" => :bedrock,
      "cohere" => :openai  # Cohere uses OpenAI-compatible endpoint
    }.freeze

    attr_reader :provider

    def initialize(provider = nil)
      @provider = provider || default_provider
      raise NoProviderError, "No LLM provider configured or enabled" unless @provider

      validate_configuration!
      @context = build_context
    end

    # Generate a completion for a single prompt
    # @param prompt [String] The prompt to complete
    # @param options [Hash] Additional options (temperature, max_tokens, etc.)
    # @return [String] The generated text
    def complete(prompt, **options)
      messages = [ { role: "user", content: prompt } ]
      chat(messages, **options)
    end

    # Chat with the model using a message array
    # @param messages [Array<Hash>] Array of message hashes with :role and :content
    # @param options [Hash] Additional options
    # @return [String] The assistant's response
    def chat(messages, **options)
      chat_instance = build_chat(options)
      response = send_messages(chat_instance, messages)
      extract_response_text(response)
    rescue RubyLLM::Error => e
      handle_ruby_llm_error(e)
    end

    # Generate structured JSON output
    # @param prompt [String] The prompt describing what to generate
    # @param schema [Hash] JSON schema for the expected output
    # @param options [Hash] Additional options
    # @return [Hash] The parsed JSON response
    def generate_json(prompt, schema: nil, **options)
      json_prompt = build_json_prompt(prompt, schema)
      response = complete(json_prompt, **options)
      parse_json_response(response)
    end

    private

    def default_provider
      LlmProvider.default_provider
    end

    # Providers that require an API key (all except ollama)
    PROVIDERS_REQUIRING_API_KEY = %w[openai anthropic azure_openai cohere bedrock].freeze

    def validate_configuration!
      raise ConfigurationError, "Provider must have a model name" if provider.llm_model.blank?

      # Validate API key requirements
      return unless PROVIDERS_REQUIRING_API_KEY.include?(provider.provider_type)
      return unless provider.api_key.blank?

      message = provider.provider_type == "bedrock" ? "API key and secret" : "an API key"
      raise ConfigurationError, "#{provider.provider_type.titleize} adapter requires #{message}"
    end

    # Build an isolated RubyLLM context with our provider's settings
    def build_context
      RubyLLM.context do |config|
        config.request_timeout = timeout_setting
        configure_provider(config)
      end
    end

    # Configure provider-specific settings
    # All valid provider_types from LlmProvider::PROVIDER_TYPES must be handled
    def configure_provider(config)
      send("configure_#{provider.provider_type}", config)
    end

    def configure_openai(config)
      config.openai_api_key = provider.api_key
      config.openai_api_base = provider.api_endpoint if provider.api_endpoint.present?
    end

    def configure_anthropic(config)
      config.anthropic_api_key = provider.api_key
    end

    def configure_ollama(config)
      config.ollama_api_base = ollama_endpoint
    end

    def configure_azure_openai(config)
      # Azure uses OpenAI-compatible API
      config.openai_api_key = provider.api_key
      config.openai_api_base = provider.api_endpoint
    end

    def configure_cohere(config)
      # Cohere uses OpenAI-compatible endpoint
      config.openai_api_key = provider.api_key
      config.openai_api_base = provider.api_endpoint
    end

    def configure_bedrock(config)
      config.bedrock_api_key = provider.api_key
      # settings column is NOT NULL with default {}, so safe navigation not needed
      config.bedrock_secret_key = provider.settings.dig("secret_key")
      config.bedrock_region = provider.settings.dig("region") || "us-east-1"
    end

    def build_chat(options)
      chat_options = {
        model: provider.llm_model,
        assume_model_exists: true,  # Allow custom/local models not in registry
        # All valid provider_types have a mapping in PROVIDER_MAP
        provider: PROVIDER_MAP.fetch(provider.provider_type)
      }

      @context.chat(**chat_options)
    end

    def send_messages(chat_instance, messages)
      # Build message content for ruby_llm
      # ruby_llm expects a single ask call, so we need to handle multi-turn differently
      if messages.length == 1
        chat_instance.ask(messages.first[:content])
      else
        # For multi-turn, set system message if present, then ask with context
        system_msg = messages.find { |m| m[:role].to_s == "system" }
        user_msgs = messages.reject { |m| m[:role].to_s == "system" }

        if system_msg
          chat_instance.with_instructions(system_msg[:content])
        end

        # Send messages in sequence to build conversation
        response = nil
        user_msgs.each do |msg|
          if msg[:role].to_s == "user"
            response = chat_instance.ask(msg[:content])
          end
        end
        response
      end
    end

    def extract_response_text(response)
      return "" if response.nil?

      # ruby_llm returns a Message object with content
      if response.respond_to?(:content)
        response.content.to_s
      else
        response.to_s
      end
    end

    def handle_ruby_llm_error(error)
      error_message = error.message.to_s.downcase

      if error_message.include?("rate limit") || error_message.include?("429")
        raise ApiError, "Rate limit exceeded: #{error.message}"
      elsif error_message.include?("invalid") && error_message.include?("key")
        raise ConfigurationError, "Invalid API key: #{error.message}"
      elsif error_message.include?("not found")
        raise ConfigurationError, "Model not found: #{error.message}"
      else
        raise ApiError, "LLM error: #{error.message}"
      end
    end

    def ollama_endpoint
      base = provider.api_endpoint.presence || "http://localhost:11434"
      # ruby_llm expects /v1 suffix for Ollama
      base.end_with?("/v1") ? base : "#{base}/v1"
    end

    def timeout_setting
      # settings column is NOT NULL with default {}, so safe navigation not needed
      provider.settings.dig("timeout") || 120
    end

    # Build a prompt that encourages JSON output
    def build_json_prompt(prompt, schema)
      parts = [ prompt ]
      parts << "\n\nRespond with valid JSON only. No other text or explanation."

      if schema
        parts << "\n\nThe JSON should follow this schema:"
        parts << "```json"
        parts << JSON.pretty_generate(schema)
        parts << "```"
      end

      parts.join
    end

    # Parse JSON from response, handling markdown code blocks
    def parse_json_response(response)
      # Remove markdown code blocks if present
      cleaned = response.strip
      cleaned = cleaned.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "")

      JSON.parse(cleaned)
    rescue JSON::ParserError => e
      raise ApiError, "Failed to parse JSON response: #{e.message}\nResponse: #{response}"
    end
  end

  # Module-level convenience methods
  class << self
    # Check if an LLM service is available
    def available?
      LlmProvider.available?
    end

    # Get the default provider
    def default_provider
      LlmProvider.default_provider
    end

    # Create a new client instance
    def client(provider = nil)
      Client.new(provider)
    end
  end
end
