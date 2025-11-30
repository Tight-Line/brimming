# frozen_string_literal: true

require "net/http"
require "json"

module EmbeddingService
  module Adapters
    class Ollama < Base
      DEFAULT_ENDPOINT = "http://localhost:11434"

      protected

      def validate_configuration!
        super
        raise ConfigurationError, "Ollama adapter requires an API endpoint" if api_endpoint.blank?
      end

      def generate_embeddings(texts)
        # Ollama doesn't support batch embeddings natively, so we process one at a time
        truncated_texts = texts.map { |t| truncate_text(t) }
        truncated_texts.map { |text| generate_single_embedding(text) }
      end

      private

      def generate_single_embedding(text)
        uri = URI("#{endpoint}/api/embed")

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request.body = {
          model: embedding_model,
          input: text
        }.to_json

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.read_timeout = settings["timeout"] || 120
        http.open_timeout = settings["timeout"] || 120

        response = http.request(request)

        handle_response_status(response)
        parse_single_response(response.body)
      rescue Errno::ECONNREFUSED
        raise ConfigurationError, "Cannot connect to Ollama at #{endpoint}. Is Ollama running?"
      end

      def handle_response_status(response)
        case response.code.to_i
        when 200..299
          # Success
        when 404
          raise ConfigurationError, "Ollama model '#{embedding_model}' not found. Pull it with: ollama pull #{embedding_model}"
        when 400..499
          raise ApiError, "Ollama API client error (#{response.code}): #{response.body}"
        when 500..599
          raise ApiError, "Ollama API server error (#{response.code}): #{response.body}"
        else
          raise ApiError, "Unexpected Ollama API response (#{response.code}): #{response.body}"
        end
      end

      def parse_single_response(body)
        data = JSON.parse(body)
        # /api/embed returns { embeddings: [[...]] } for single input
        embeddings = data["embeddings"]
        if embeddings.is_a?(Array) && embeddings.first.is_a?(Array)
          embeddings.first
        else
          raise ApiError, "Unexpected Ollama embeddings format: #{data.keys}"
        end
      rescue JSON::ParserError => e
        raise ApiError, "Failed to parse Ollama response: #{e.message}"
      end

      def endpoint
        api_endpoint.presence || DEFAULT_ENDPOINT
      end
    end
  end
end
