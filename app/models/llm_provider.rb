# frozen_string_literal: true

require "net/http"

class LlmProvider < ApplicationRecord
  PROVIDER_TYPES = %w[openai anthropic ollama azure_openai bedrock cohere].freeze

  # Available models per provider (newest first, then alphabetized within generation)
  # Note: Ollama models are discovered dynamically via OllamaDiscoveryService
  # Last updated: December 2025
  MODELS = {
    "openai" => %w[
      gpt-5.2-chat-latest
      gpt-5.2
      gpt-5.2-pro
      gpt-5-chat-latest
      gpt-5
      gpt-5-mini
      gpt-5-nano
      gpt-5-codex
      gpt-5-pro
      gpt-5-search-api
      gpt-5.1-chat-latest
      gpt-5.1
      gpt-5.1-codex
      gpt-5.1-codex-mini
      gpt-5.1-codex-max
      o3
      o3-mini
      o4-mini
      gpt-4.1
      gpt-4.1-mini
      gpt-4.1-nano
      gpt-4o
      gpt-4o-mini
      gpt-4-turbo
      gpt-4
      gpt-3.5-turbo
    ],
    "anthropic" => %w[
      claude-opus-4-5-20251101
      claude-sonnet-4-5-20250929
      claude-haiku-4-5-20251001
      claude-opus-4-1-20250805
      claude-sonnet-4-20250514
      claude-opus-4-20250514
      claude-3-7-sonnet-20250219
      claude-3-5-haiku-20241022
      claude-3-haiku-20240307
    ],
    "azure_openai" => %w[
      o3
      o3-mini
      o4-mini
      gpt-4.1
      gpt-4.1-mini
      gpt-4o
      gpt-4o-mini
      gpt-4-turbo
      gpt-4
      gpt-35-turbo
    ],
    "bedrock" => %w[
      anthropic.claude-opus-4-5-20251101-v1:0
      anthropic.claude-sonnet-4-5-20250929-v1:0
      anthropic.claude-haiku-4-5-20251001-v1:0
      anthropic.claude-opus-4-1-20250805-v1:0
      anthropic.claude-sonnet-4-20250514-v1:0
      anthropic.claude-opus-4-20250514-v1:0
      anthropic.claude-3-7-sonnet-20250219-v1:0
      anthropic.claude-3-5-haiku-20241022-v1:0
      meta.llama4-maverick-17b-instruct-v1:0
      meta.llama4-scout-17b-instruct-v1:0
      meta.llama3-3-70b-instruct-v1:0
      meta.llama3-1-405b-instruct-v1:0
      meta.llama3-1-70b-instruct-v1:0
      amazon.titan-text-premier-v1:0
    ],
    "cohere" => %w[
      command-a-03-2025
      command-r-plus-08-2024
      command-r-08-2024
      command-r-plus
      command-r
    ]
  }.freeze

  # Default API endpoints for providers that require them
  DEFAULT_ENDPOINTS = {
    "ollama" => "http://localhost:11434",
    "azure_openai" => nil  # Customer-specific URL required
  }.freeze

  # Default settings per provider
  DEFAULT_SETTINGS = {
    "temperature" => 0.7,
    "max_tokens" => 2048
  }.freeze

  encrypts :api_key

  validates :name, presence: true, uniqueness: true
  validates :provider_type, presence: true, inclusion: { in: PROVIDER_TYPES }
  validates :llm_model, presence: true
  validate :api_endpoint_required_for_provider
  validate :api_endpoint_reachable, if: :should_validate_endpoint_reachability?
  validate :only_one_default

  before_validation :set_default_api_endpoint
  after_save :ensure_single_default, if: :saved_change_to_is_default?
  after_create :set_as_default_if_first

  scope :enabled, -> { where(enabled: true) }
  scope :by_default, -> { where(is_default: true) }

  def self.default_provider
    by_default.enabled.first || enabled.first
  end

  def self.available?
    enabled.exists?
  end

  def display_provider_type
    case provider_type
    when "openai" then "OpenAI"
    when "anthropic" then "Anthropic"
    when "ollama" then "Ollama (Self-hosted)"
    when "azure_openai" then "Azure OpenAI"
    when "bedrock" then "AWS Bedrock"
    when "cohere" then "Cohere"
    when nil, "" then "Not Selected"
    else provider_type.titleize
    end
  end

  def requires_api_key?
    %w[openai anthropic azure_openai bedrock cohere].include?(provider_type)
  end

  def requires_api_endpoint?
    %w[ollama azure_openai].include?(provider_type)
  end

  # Ollama uses dynamic model discovery - models are fetched from the running instance
  def uses_dynamic_models?
    provider_type == "ollama"
  end

  def can_delete?
    !enabled?
  end

  # Settings accessors with defaults
  def temperature
    settings["temperature"]&.to_f || DEFAULT_SETTINGS["temperature"]
  end

  def temperature=(value)
    self.settings = settings.merge("temperature" => value.to_f.clamp(0.0, 2.0))
  end

  def max_tokens
    settings["max_tokens"]&.to_i || DEFAULT_SETTINGS["max_tokens"]
  end

  def max_tokens=(value)
    self.settings = settings.merge("max_tokens" => value.to_i.clamp(1, 128_000))
  end

  # Available models for this provider's type
  def available_models
    self.class.models_for(provider_type)
  end

  def self.models_for(provider_type)
    MODELS[provider_type] || []
  end

  def self.default_model_for(provider_type)
    models_for(provider_type).first
  end

  private

  def api_endpoint_required_for_provider
    if requires_api_endpoint? && api_endpoint.blank?
      errors.add(:api_endpoint, "is required for #{display_provider_type}")
    end
  end

  def api_endpoint_reachable
    uri = URI.parse(api_endpoint)
    unless uri.host.present?
      errors.add(:api_endpoint, "is not a valid URL")
      return
    end

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 5
    http.read_timeout = 5

    http.request(Net::HTTP::Head.new(uri.path.presence || "/"))
  rescue URI::InvalidURIError
    errors.add(:api_endpoint, "is not a valid URL")
  rescue Errno::ECONNREFUSED
    errors.add(:api_endpoint, "connection refused - is the service running?")
  rescue Errno::EHOSTUNREACH
    errors.add(:api_endpoint, "host is unreachable")
  rescue Errno::ENETUNREACH
    errors.add(:api_endpoint, "network is unreachable")
  rescue SocketError => e
    errors.add(:api_endpoint, "could not resolve host: #{e.message}")
  rescue Net::OpenTimeout, Timeout::Error
    errors.add(:api_endpoint, "connection timed out")
  rescue OpenSSL::SSL::SSLError => e
    errors.add(:api_endpoint, "SSL error: #{e.message}")
  rescue StandardError => e
    errors.add(:api_endpoint, "could not connect: #{e.message}")
  end

  def should_validate_endpoint_reachability?
    api_endpoint.present? && api_endpoint_changed?
  end

  def set_default_api_endpoint
    return if api_endpoint.present? || provider_type.blank?

    default = DEFAULT_ENDPOINTS[provider_type]
    self.api_endpoint = default if default.present?
  end

  def only_one_default
    return unless is_default? && is_default_changed?

    if LlmProvider.where(is_default: true).where.not(id: id).exists?
      # Don't add error, we'll handle this in after_save
    end
  end

  def ensure_single_default
    return unless is_default?

    LlmProvider.where(is_default: true).where.not(id: id).update_all(is_default: false)
  end

  def set_as_default_if_first
    return if LlmProvider.count > 1

    update_columns(enabled: true, is_default: true)
  end
end
