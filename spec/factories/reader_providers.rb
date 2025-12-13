# frozen_string_literal: true

FactoryBot.define do
  factory :reader_provider do
    sequence(:name) { |n| "Reader Provider #{n}" }
    provider_type { "jina" }
    api_key { "test-api-key-#{SecureRandom.hex(8)}" }
    api_endpoint { "https://r.jina.ai" }
    enabled { false }
    settings { {} }

    trait :enabled do
      enabled { true }
    end

    trait :jina do
      provider_type { "jina" }
      api_endpoint { "https://r.jina.ai" }
    end

    trait :firecrawl do
      provider_type { "firecrawl" }
      api_endpoint { "https://api.firecrawl.dev" }
      api_key { "fc-test-key-#{SecureRandom.hex(8)}" }
    end
  end
end
