# frozen_string_literal: true

require "net/http"
require "json"

module EmbeddingService
  module Adapters
    class Cohere < Base
      DEFAULT_ENDPOINT = "https://api.cohere.com/v1"

      protected

      def validate_configuration!
        super
        raise ConfigurationError, "Cohere adapter requires an API key" if api_key.blank?
      end

      def generate_embeddings(texts)
        with_retry do
          truncated_texts = texts.map { |t| truncate_text(t) }
          response = make_request(truncated_texts)
          parse_response(response)
        end
      end

      private

      def make_request(texts)
        uri = URI("#{endpoint}/embed")

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{api_key}"
        request["Content-Type"] = "application/json"

        body = {
          model: embedding_model,
          texts: texts,
          input_type: "search_document",
          truncate: "END"
        }

        # Cohere v3 models support embedding_types for different use cases
        if embedding_model.include?("v3")
          body[:embedding_types] = [ "float" ]
        end

        request.body = body.to_json

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.read_timeout = settings["timeout"] || 60
        http.open_timeout = settings["timeout"] || 60

        response = http.request(request)

        handle_response_status(response)
        response.body
      end

      def handle_response_status(response)
        case response.code.to_i
        when 200..299
          # Success
        when 429
          raise RateLimitError, "Cohere rate limit exceeded: #{response.body}"
        when 401
          raise ConfigurationError, "Invalid Cohere API key"
        when 400..499
          raise ApiError, "Cohere API client error (#{response.code}): #{response.body}"
        when 500..599
          raise ApiError, "Cohere API server error (#{response.code}): #{response.body}"
        else
          raise ApiError, "Unexpected Cohere API response (#{response.code}): #{response.body}"
        end
      end

      def parse_response(body)
        data = JSON.parse(body)

        # Cohere v3 models return embeddings in a different format
        if data["embeddings"].is_a?(Hash) && data["embeddings"]["float"]
          data["embeddings"]["float"]
        else
          data["embeddings"]
        end
      rescue JSON::ParserError => e
        raise ApiError, "Failed to parse Cohere response: #{e.message}"
      end

      def endpoint
        api_endpoint.presence || DEFAULT_ENDPOINT
      end
    end
  end
end
