# frozen_string_literal: true

# SMTP Configuration
# Configure Action Mailer to use SMTP with environment variables
# This allows flexible configuration across different environments
# Skip in test environment - tests use the :test delivery method

if ENV["SMTP_HOST"].present? && !Rails.env.test?
  Rails.application.config.action_mailer.delivery_method = :smtp

  smtp_settings = {
    address: ENV.fetch("SMTP_HOST"),
    port: ENV.fetch("SMTP_PORT", 587).to_i
  }

  # TLS/SSL configuration
  # Note: For servers without TLS support, set SMTP_TLS=false
  # This disables both TLS and STARTTLS to avoid connection errors
  if ENV["SMTP_TLS"] == "true"
    smtp_settings[:enable_starttls_auto] = true
  elsif ENV["SMTP_TLS"] == "false"
    smtp_settings[:tls] = false
    smtp_settings[:enable_starttls_auto] = false
  end

  # Authentication (optional)
  if ENV["SMTP_USER"].present?
    smtp_settings[:user_name] = ENV["SMTP_USER"]
    smtp_settings[:password] = ENV["SMTP_PASS"]
    smtp_settings[:authentication] = ENV.fetch("SMTP_AUTH", "plain").to_sym
  end

  # Domain for HELO (optional)
  smtp_settings[:domain] = ENV["SMTP_DOMAIN"] if ENV["SMTP_DOMAIN"].present?

  Rails.application.config.action_mailer.smtp_settings = smtp_settings
end

# Default from address
if ENV["MAILER_FROM"].present?
  Rails.application.config.action_mailer.default_options = {
    from: ENV["MAILER_FROM"]
  }
end
