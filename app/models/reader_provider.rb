# frozen_string_literal: true

class ReaderProvider < ApplicationRecord
  PROVIDER_TYPES = %w[jina firecrawl].freeze

  # Default API endpoints for providers
  DEFAULT_ENDPOINTS = {
    "jina" => "https://r.jina.ai",
    "firecrawl" => "https://api.firecrawl.dev"
  }.freeze

  encrypts :api_key

  validates :name, presence: true, uniqueness: true
  validates :provider_type, presence: true, inclusion: { in: PROVIDER_TYPES }
  validate :api_endpoint_is_valid_url

  before_validation :set_default_api_endpoint
  after_create :enable_if_first

  scope :enabled, -> { where(enabled: true) }

  def display_provider_type
    case provider_type
    when "jina" then "Jina.ai Reader"
    when "firecrawl" then "Firecrawl"
    when nil, "" then "Not Selected"
    else provider_type.titleize
    end
  end

  def requires_api_key?
    # Both Jina and Firecrawl cloud require API keys
    true
  end

  def can_delete?
    !enabled?
  end

  # Check if a reader provider is configured and enabled
  def self.available?
    enabled.exists?
  end

  # Get the currently enabled provider
  def self.enabled_provider
    enabled.first
  end

  private

  def set_default_api_endpoint
    return if api_endpoint.present? || provider_type.blank?

    # All valid provider_types have entries in DEFAULT_ENDPOINTS (enforced by validation)
    self.api_endpoint = DEFAULT_ENDPOINTS[provider_type]
  end

  def enable_if_first
    return if ReaderProvider.count > 1

    update_column(:enabled, true)
  end

  def api_endpoint_is_valid_url
    return if api_endpoint.blank?

    uri = URI.parse(api_endpoint)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      errors.add(:api_endpoint, "must be a valid HTTP or HTTPS URL")
    end
  rescue URI::InvalidURIError
    errors.add(:api_endpoint, "must be a valid URL")
  end
end
