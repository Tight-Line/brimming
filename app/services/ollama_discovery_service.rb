# frozen_string_literal: true

require "net/http"
require "json"

# Service to discover Ollama instances and their available models
class OllamaDiscoveryService
  class Error < StandardError; end

  # Common endpoints to try when auto-detecting Ollama
  DEFAULT_ENDPOINTS = [
    "http://host.docker.internal:11434",  # Docker host from container
    "http://localhost:11434",              # Local machine
    "http://127.0.0.1:11434"               # Explicit localhost
  ].freeze

  # Known embedding model name patterns (Ollama API doesn't distinguish model types)
  # These are filtered out when fetching LLM models
  EMBEDDING_MODEL_PATTERNS = [
    /^all-minilm/i,
    /^bge-/i,
    /^e5-/i,
    /^embed/i,
    /^granite-embedding/i,
    /^mxbai-embed/i,
    /^nomic-embed/i,
    /^paraphrase/i,
    /^snowflake-arctic-embed/i,
    /^qwen.*-embedding/i
  ].freeze

  TIMEOUT = 3 # seconds

  class << self
    # Auto-detect an available Ollama instance
    # @return [String, nil] The first reachable endpoint, or nil if none found
    def detect_endpoint
      DEFAULT_ENDPOINTS.find { |endpoint| reachable?(endpoint) }
    end

    # Check if an Ollama endpoint is reachable
    # @param endpoint [String] The base URL (e.g., "http://localhost:11434")
    # @return [Boolean]
    def reachable?(endpoint)
      uri = URI.parse("#{endpoint}/api/tags")
      http = build_http(uri)
      response = http.request(Net::HTTP::Get.new(uri.path))
      response.is_a?(Net::HTTPSuccess)
    rescue StandardError
      false
    end

    # Fetch available models from an Ollama instance
    # @param endpoint [String] The base URL (e.g., "http://localhost:11434")
    # @param type [Symbol] :llm for language models only, :embedding for embedding models only, :all for both
    # @return [Array<Hash>] Array of model info hashes with :name, :size, :parameter_size
    def fetch_models(endpoint, type: :llm)
      uri = URI.parse("#{endpoint}/api/tags")
      http = build_http(uri)
      response = http.request(Net::HTTP::Get.new(uri.path))

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "Failed to fetch models: HTTP #{response.code}"
      end

      parse_models_response(response.body, type: type)
    rescue JSON::ParserError => e
      raise Error, "Invalid JSON response: #{e.message}"
    rescue StandardError => e
      raise Error, "Failed to connect to Ollama: #{e.message}"
    end

    # Fetch just the model names from an Ollama instance
    # @param endpoint [String] The base URL
    # @param type [Symbol] :llm, :embedding, or :all
    # @return [Array<String>] Array of model names (e.g., ["llama3.2:latest", "mistral:7b"])
    def fetch_model_names(endpoint, type: :llm)
      fetch_models(endpoint, type: type).map { |m| m[:name] }
    end

    private

    def build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = TIMEOUT
      http.read_timeout = TIMEOUT
      http
    end

    def parse_models_response(body, type: :llm)
      data = JSON.parse(body)
      models = data["models"] || []

      parsed = models.map do |model|
        name = model["name"] || model["model"]
        {
          name: name,
          size: model["size"],
          parameter_size: model.dig("details", "parameter_size"),
          family: model.dig("details", "family"),
          quantization: model.dig("details", "quantization_level"),
          is_embedding: embedding_model?(name)
        }
      end

      # Filter based on requested type
      filtered = case type
      when :llm
        parsed.reject { |m| m[:is_embedding] }
      when :embedding
        parsed.select { |m| m[:is_embedding] }
      else
        parsed
      end

      filtered.sort_by { |m| m[:name].to_s.downcase }
    end

    def embedding_model?(name)
      base_name = name.to_s.split(":").first.downcase
      EMBEDDING_MODEL_PATTERNS.any? { |pattern| base_name.match?(pattern) }
    end
  end
end
