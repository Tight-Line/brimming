# frozen_string_literal: true

class ReaderProvider < ApplicationRecord
  PROVIDER_TYPES = %w[jina firecrawl].freeze

  # Default API endpoints for providers
  DEFAULT_ENDPOINTS = {
    "jina" => "https://r.jina.ai",
    "firecrawl" => "http://firecrawl:3002"
  }.freeze

  encrypts :api_key

  validates :name, presence: true, uniqueness: true
  validates :provider_type, presence: true, inclusion: { in: PROVIDER_TYPES }

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
    # Firecrawl self-hosted doesn't require an API key
    provider_type != "firecrawl"
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

    default = DEFAULT_ENDPOINTS[provider_type]
    self.api_endpoint = default if default.present?
  end

  def enable_if_first
    return if ReaderProvider.count > 1

    update_column(:enabled, true)
  end
end
