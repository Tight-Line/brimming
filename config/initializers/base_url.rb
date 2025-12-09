# frozen_string_literal: true

# Base URL Configuration
# Configure the external URL for mailer links and other URL generation.
# This is useful when the app runs behind a reverse proxy or in Docker.
#
# Set BRIMMING_BASE_URL to the externally accessible URL, e.g.:
#   BRIMMING_BASE_URL=http://localhost:33000
#   BRIMMING_BASE_URL=https://brimming.example.com

if ENV["BRIMMING_BASE_URL"].present?
  uri = URI.parse(ENV["BRIMMING_BASE_URL"])

  url_options = {
    host: uri.host,
    protocol: uri.scheme
  }

  # Only include port if it's non-standard
  if uri.port && !((uri.scheme == "http" && uri.port == 80) || (uri.scheme == "https" && uri.port == 443))
    url_options[:port] = uri.port
  end

  Rails.application.config.action_mailer.default_url_options = url_options

  # Also set default_url_options for controllers (used by url_for helpers)
  Rails.application.routes.default_url_options = url_options
end
