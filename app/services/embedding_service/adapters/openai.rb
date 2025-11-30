# frozen_string_literal: true

require "net/http"
require "json"

module EmbeddingService
  module Adapters
    class Openai < Base
      DEFAULT_ENDPOINT = "https://api.openai.com/v1"

      protected

      def validate_configuration!
        super
        raise ConfigurationError, "OpenAI adapter requires an API key" if api_key.blank?
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
        uri = URI("#{endpoint}/embeddings")

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{api_key}"
        request["Content-Type"] = "application/json"
        request.body = {
          model: embedding_model,
          input: texts,
          dimensions: dimensions
        }.to_json

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
          raise RateLimitError, "OpenAI rate limit exceeded: #{response.body}"
        when 401
          raise ConfigurationError, "Invalid OpenAI API key"
        when 400..499
          raise ApiError, "OpenAI API client error (#{response.code}): #{response.body}"
        when 500..599
          raise ApiError, "OpenAI API server error (#{response.code}): #{response.body}"
        else
          raise ApiError, "Unexpected OpenAI API response (#{response.code}): #{response.body}"
        end
      end

      def parse_response(body)
        data = JSON.parse(body)

        # OpenAI returns embeddings sorted by index
        data["data"]
          .sort_by { |d| d["index"] }
          .map { |d| d["embedding"] }
      rescue JSON::ParserError => e
        raise ApiError, "Failed to parse OpenAI response: #{e.message}"
      end

      def endpoint
        api_endpoint.presence || DEFAULT_ENDPOINT
      end
    end
  end
end
