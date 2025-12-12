# frozen_string_literal: true

FactoryBot.define do
  factory :llm_provider do
    sequence(:name) { |n| "LLM Provider #{n}" }
    provider_type { "openai" }
    llm_model { "gpt-4o" }
    api_key { "sk-test-key-12345" }
    enabled { false }
    is_default { false }

    trait :openai do
      provider_type { "openai" }
      llm_model { "gpt-4o" }
      api_key { "sk-test-key-12345" }
    end

    trait :anthropic do
      provider_type { "anthropic" }
      llm_model { "claude-sonnet-4-5-20250929" }
      api_key { "sk-ant-test-key" }
    end

    trait :ollama do
      provider_type { "ollama" }
      llm_model { "llama3" }
      api_endpoint { "http://localhost:11434" }
    end

    trait :enabled do
      enabled { true }
    end

    trait :default do
      enabled { true }
      is_default { true }
    end
  end
end
