# frozen_string_literal: true

# Active Record Encryption configuration
# Used by models with `encrypts` attribute declarations (e.g., EmbeddingProvider.api_key)

Rails.application.config.active_record.encryption.primary_key =
  Rails.application.credentials.dig(:active_record_encryption, :primary_key) ||
  ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY", nil) ||
  (Rails.env.local? ? "test-primary-key-for-dev-only" : nil)

Rails.application.config.active_record.encryption.deterministic_key =
  Rails.application.credentials.dig(:active_record_encryption, :deterministic_key) ||
  ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY", nil) ||
  (Rails.env.local? ? "test-deterministic-key-for-dev-only" : nil)

Rails.application.config.active_record.encryption.key_derivation_salt =
  Rails.application.credentials.dig(:active_record_encryption, :key_derivation_salt) ||
  ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT", nil) ||
  (Rails.env.local? ? "test-key-derivation-salt-for-dev-only" : nil)
