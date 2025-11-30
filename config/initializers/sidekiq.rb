# frozen_string_literal: true

# Sidekiq configuration for background job processing
# Uses REDIS_URL environment variable (defaults to localhost for development outside Docker)

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
