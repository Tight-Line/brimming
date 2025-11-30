# frozen_string_literal: true

module EmbeddingService
  module Adapters
    class Base
      class Error < StandardError; end
      class ConfigurationError < Error; end
      class ApiError < Error; end
      class RateLimitError < ApiError; end

      attr_reader :provider

      def initialize(provider)
        @provider = provider
        validate_configuration!
      end

      # Generate embeddings for one or more texts
      # @param texts [String, Array<String>] The text(s) to embed
      # @return [Array<Array<Float>>] Array of embedding vectors
      def embed(texts)
        texts = Array(texts)
        return [] if texts.empty?

        generate_embeddings(texts)
      end

      # Generate embedding for a single text
      # @param text [String] The text to embed
      # @return [Array<Float>] The embedding vector
      def embed_one(text)
        result = embed([ text ])
        result.first
      end

      protected

      # Subclasses must implement this method
      def generate_embeddings(texts)
        raise NotImplementedError, "Subclasses must implement #generate_embeddings"
      end

      # Subclasses can override to add specific validation
      def validate_configuration!
        # Base validation - ensure required fields are present
        raise ConfigurationError, "Provider must have an embedding model" if provider.embedding_model.blank?
        raise ConfigurationError, "Provider must have dimensions specified" if provider.dimensions.blank?
      end

      def api_key
        provider.api_key
      end

      def api_endpoint
        provider.api_endpoint
      end

      def embedding_model
        provider.embedding_model
      end

      def dimensions
        provider.dimensions
      end

      def settings
        provider.settings || {}
      end

      # Truncate text to fit within the model's context window
      # Uses the provider's max_input_chars which is model-specific
      def truncate_text(text)
        max_chars = provider.max_input_chars
        return text if text.length <= max_chars

        # Truncate and add indicator that text was cut
        truncated = text[0, max_chars - 3]
        "#{truncated}..."
      end

      # Retry with exponential backoff for rate limits
      def with_retry(max_attempts: 3, base_delay: 1)
        attempts = 0
        begin
          attempts += 1
          yield
        rescue RateLimitError => e
          if attempts < max_attempts
            delay = base_delay * (2 ** (attempts - 1))
            Rails.logger.warn("[EmbeddingService] Rate limited, retrying in #{delay}s (attempt #{attempts}/#{max_attempts})")
            sleep(delay)
            retry
          else
            raise
          end
        end
      end
    end
  end
end
