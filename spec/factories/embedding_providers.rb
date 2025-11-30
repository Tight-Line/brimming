# frozen_string_literal: true

FactoryBot.define do
  factory :embedding_provider do
    sequence(:name) { |n| "Embedding Provider #{n}" }
    provider_type { "openai" }
    embedding_model { "text-embedding-3-small" }
    dimensions { 1536 }
    enabled { false }

    trait :openai do
      provider_type { "openai" }
      embedding_model { "text-embedding-3-small" }
      dimensions { 1536 }
      api_key { "sk-test-key-12345" }
    end

    trait :cohere do
      provider_type { "cohere" }
      embedding_model { "embed-english-v3.0" }
      dimensions { 1024 }
      api_key { "cohere-test-key" }
    end

    trait :ollama do
      provider_type { "ollama" }
      embedding_model { "nomic-embed-text" }
      dimensions { 768 }
      api_endpoint { "http://localhost:11434" }
    end

    trait :enabled do
      enabled { true }
    end
  end
end
