# frozen_string_literal: true

class EmbeddingProvider < ApplicationRecord
  PROVIDER_TYPES = %w[openai cohere ollama azure_openai bedrock huggingface].freeze

  # Default similarity thresholds per model
  # Different models have very different score distributions, so thresholds
  # must be tuned per-model rather than per-provider-type.
  #
  # These were determined empirically by testing queries against known-relevant
  # and known-irrelevant documents.
  DEFAULT_SIMILARITY_THRESHOLDS = {
    # OpenAI models (lower scores, ~0.15-0.35 range)
    "text-embedding-3-small" => 0.28,
    "text-embedding-3-large" => 0.28,
    "text-embedding-ada-002" => 0.28,
    # Cohere models
    "embed-english-v3.0" => 0.30,
    "embed-multilingual-v3.0" => 0.30,
    "embed-english-light-v3.0" => 0.28,
    "embed-multilingual-light-v3.0" => 0.28,
    # Ollama models (vary widely)
    "embeddinggemma" => 0.38,
    "nomic-embed-text" => 0.42,
    "mxbai-embed-large" => 0.35,
    "all-minilm" => 0.30,
    "snowflake-arctic-embed" => 0.32,
    # Azure OpenAI (same as OpenAI)
    # Bedrock models
    "amazon.titan-embed-text-v1" => 0.25,
    "amazon.titan-embed-text-v2:0" => 0.25,
    "cohere.embed-english-v3" => 0.30,
    "cohere.embed-multilingual-v3" => 0.30,
    # HuggingFace models
    "sentence-transformers/all-MiniLM-L6-v2" => 0.30,
    "sentence-transformers/all-mpnet-base-v2" => 0.32,
    "BAAI/bge-small-en-v1.5" => 0.32,
    "BAAI/bge-base-en-v1.5" => 0.32
  }.freeze

  # Fallback thresholds by provider type (used if model not in above list)
  PROVIDER_TYPE_THRESHOLDS = {
    "openai" => 0.28,
    "cohere" => 0.30,
    "azure_openai" => 0.28,
    "bedrock" => 0.25,
    "huggingface" => 0.30,
    "ollama" => 0.35
  }.freeze

  # Available models per provider with their dimensions
  MODELS = {
    "openai" => {
      "text-embedding-3-small" => 1536,
      "text-embedding-3-large" => 3072,
      "text-embedding-ada-002" => 1536
    },
    "cohere" => {
      "embed-english-v3.0" => 1024,
      "embed-multilingual-v3.0" => 1024,
      "embed-english-light-v3.0" => 384,
      "embed-multilingual-light-v3.0" => 384
    },
    "ollama" => {
      "embeddinggemma" => 768,
      "nomic-embed-text" => 768,
      "mxbai-embed-large" => 1024,
      "all-minilm" => 384,
      "snowflake-arctic-embed" => 1024
    },
    "azure_openai" => {
      "text-embedding-ada-002" => 1536,
      "text-embedding-3-small" => 1536,
      "text-embedding-3-large" => 3072
    },
    "bedrock" => {
      "amazon.titan-embed-text-v1" => 1536,
      "amazon.titan-embed-text-v2:0" => 1024,
      "cohere.embed-english-v3" => 1024,
      "cohere.embed-multilingual-v3" => 1024
    },
    "huggingface" => {
      "sentence-transformers/all-MiniLM-L6-v2" => 384,
      "sentence-transformers/all-mpnet-base-v2" => 768,
      "BAAI/bge-small-en-v1.5" => 384,
      "BAAI/bge-base-en-v1.5" => 768
    }
  }.freeze

  # Maximum context length in tokens per model
  # Used to truncate input text before embedding
  MAX_TOKENS = {
    # OpenAI models
    "text-embedding-3-small" => 8191,
    "text-embedding-3-large" => 8191,
    "text-embedding-ada-002" => 8191,
    # Cohere models (v3 supports 512 tokens for search)
    "embed-english-v3.0" => 512,
    "embed-multilingual-v3.0" => 512,
    "embed-english-light-v3.0" => 512,
    "embed-multilingual-light-v3.0" => 512,
    # Ollama models (conservative limits due to tokenization variance on code)
    "embeddinggemma" => 2048,
    "nomic-embed-text" => 600,
    "mxbai-embed-large" => 512,
    "all-minilm" => 256,
    "snowflake-arctic-embed" => 512,
    # Bedrock models
    "amazon.titan-embed-text-v1" => 8000,
    "amazon.titan-embed-text-v2:0" => 8000,
    "cohere.embed-english-v3" => 512,
    "cohere.embed-multilingual-v3" => 512,
    # HuggingFace models
    "sentence-transformers/all-MiniLM-L6-v2" => 256,
    "sentence-transformers/all-mpnet-base-v2" => 384,
    "BAAI/bge-small-en-v1.5" => 512,
    "BAAI/bge-base-en-v1.5" => 512
  }.freeze

  # Average characters per token (conservative estimate)
  CHARS_PER_TOKEN = 3

  # Default API endpoints for providers that require them
  DEFAULT_ENDPOINTS = {
    "ollama" => "http://localhost:11434",
    "azure_openai" => nil  # No sensible default - requires customer-specific URL
  }.freeze

  encrypts :api_key

  validates :name, presence: true, uniqueness: true
  validates :provider_type, presence: true, inclusion: { in: PROVIDER_TYPES }
  validates :embedding_model, presence: true
  validates :dimensions, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 4096 }
  validate :api_endpoint_required_for_provider

  def api_endpoint_required_for_provider
    if requires_api_endpoint? && api_endpoint.blank?
      errors.add(:api_endpoint, "is required for #{display_provider_type}")
    end
  end

  before_validation :set_dimensions_from_model
  before_validation :set_default_api_endpoint
  after_create :enable_if_first

  scope :enabled, -> { where(enabled: true) }

  def display_provider_type
    case provider_type
    when "openai" then "OpenAI"
    when "cohere" then "Cohere"
    when "ollama" then "Ollama (Self-hosted)"
    when "azure_openai" then "Azure OpenAI"
    when "bedrock" then "AWS Bedrock"
    when "huggingface" then "Hugging Face"
    when nil, "" then "Not Selected"
    else provider_type.titleize
    end
  end

  def requires_api_key?
    %w[openai cohere azure_openai bedrock huggingface].include?(provider_type)
  end

  def requires_api_endpoint?
    %w[ollama azure_openai].include?(provider_type)
  end

  def can_delete?
    !enabled?
  end

  # Similarity threshold for filtering vector search results
  # Stored in settings jsonb column, falls back to provider-type default
  def similarity_threshold
    settings["similarity_threshold"]&.to_f || default_similarity_threshold
  end

  def similarity_threshold=(value)
    self.settings = settings.merge("similarity_threshold" => value.to_f)
  end

  def default_similarity_threshold
    # First try model-specific threshold, then provider-type fallback
    DEFAULT_SIMILARITY_THRESHOLDS[embedding_model] ||
      PROVIDER_TYPE_THRESHOLDS[provider_type] ||
      0.3
  end

  # Available models for this provider's type
  def available_models
    self.class.models_for(provider_type)
  end

  # Maximum input length in characters for this model
  # Used to truncate text before embedding to avoid context overflow
  def max_input_chars
    max_tokens = MAX_TOKENS[embedding_model] || 512  # Conservative default
    max_tokens * CHARS_PER_TOKEN
  end

  # Maximum input length in tokens for this model
  def max_input_tokens
    MAX_TOKENS[embedding_model] || 512
  end

  # Get models for a provider type as options for select
  def self.models_for(provider_type)
    MODELS[provider_type] || {}
  end

  # Default model for a provider type
  def self.default_model_for(provider_type)
    models_for(provider_type).keys.first
  end

  # Default config (for backwards compatibility)
  def self.default_config_for(provider_type)
    model = default_model_for(provider_type)
    dimensions = models_for(provider_type)[model] || 1536
    { embedding_model: model, dimensions: dimensions }
  end

  private

  def set_dimensions_from_model
    return if embedding_model.blank?

    model_dimensions = MODELS.dig(provider_type, embedding_model)
    self.dimensions = model_dimensions if model_dimensions
  end

  def set_default_api_endpoint
    return if api_endpoint.present? || provider_type.blank?

    default = DEFAULT_ENDPOINTS[provider_type]
    self.api_endpoint = default if default.present?
  end

  def enable_if_first
    return if EmbeddingProvider.count > 1

    update_column(:enabled, true)
  end
end
