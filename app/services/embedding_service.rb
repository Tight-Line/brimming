# frozen_string_literal: true

# Namespace module for embedding service components
module EmbeddingService
  # Main service for generating text embeddings using configured providers
  #
  # Usage:
  #   service = EmbeddingService::Client.new
  #   embedding = service.embed_one("What is Ruby on Rails?")
  #   embeddings = service.embed(["Question 1", "Question 2"])
  #
  # Or with a specific provider:
  #   provider = EmbeddingProvider.find(1)
  #   service = EmbeddingService::Client.new(provider)
  #
  class Client
    class Error < StandardError; end
    class NoProviderError < Error; end

    ADAPTER_MAP = {
      "openai" => "EmbeddingService::Adapters::Openai",
      "cohere" => "EmbeddingService::Adapters::Cohere",
      "ollama" => "EmbeddingService::Adapters::Ollama",
      "azure_openai" => "EmbeddingService::Adapters::AzureOpenai",
      "bedrock" => "EmbeddingService::Adapters::Bedrock",
      "huggingface" => "EmbeddingService::Adapters::Huggingface"
    }.freeze

    attr_reader :provider, :adapter

    def initialize(provider = nil)
      @provider = provider || default_provider
      raise NoProviderError, "No embedding provider configured or enabled" unless @provider

      @adapter = build_adapter
    end

    # Generate embeddings for one or more texts
    # @param texts [String, Array<String>] The text(s) to embed
    # @return [Array<Array<Float>>] Array of embedding vectors
    def embed(texts)
      adapter.embed(texts)
    end

    # Generate embedding for a single text
    # @param text [String] The text to embed
    # @return [Array<Float>] The embedding vector
    def embed_one(text)
      adapter.embed_one(text)
    end

    # Get the dimensions of embeddings from this provider
    def dimensions
      provider.dimensions
    end

    private

    def default_provider
      EmbeddingProvider.enabled.first
    end

    def build_adapter
      adapter_class_name = ADAPTER_MAP[provider.provider_type]
      raise Error, "Unknown provider type: #{provider.provider_type}" unless adapter_class_name

      adapter_class = adapter_class_name.constantize
      adapter_class.new(provider)
    rescue NameError
      raise Error, "Adapter not implemented for provider type: #{provider.provider_type}"
    end
  end

  # Module-level convenience methods
  class << self
    # Check if an embedding service is available
    def available?
      EmbeddingProvider.enabled.exists?
    end

    # Get the currently enabled provider
    def current_provider
      EmbeddingProvider.enabled.first
    end

    # Create a new client instance
    def client(provider = nil)
      Client.new(provider)
    end

    # Prepare text content for embedding (question + best answer)
    def prepare_question_text(question)
      parts = []

      # Add question title and body (body is always present per Question validation)
      parts << "Question: #{question.title}"
      parts << question.body

      # Add the accepted/best answer if available
      best_answer = question.answers.find_by(is_correct: true) ||
                    question.answers.order(vote_score: :desc).first

      if best_answer
        parts << "Best Answer: #{best_answer.body}"
      end

      parts.join("\n\n")
    end
  end
end
