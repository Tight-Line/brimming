# frozen_string_literal: true

# OmniAuth configuration
# LDAP providers are dynamically configured from the database
# See app/services/ldap_omniauth_strategy.rb for dynamic LDAP handling

OmniAuth.config.logger = Rails.logger

# Allow GET requests for development (POST is required in production for CSRF protection)
OmniAuth.config.allowed_request_methods = [ :post, :get ] if Rails.env.development? || Rails.env.test?

# Handle OmniAuth failures gracefully
OmniAuth.config.on_failure = proc do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end
