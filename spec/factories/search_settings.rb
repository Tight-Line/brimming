# frozen_string_literal: true

FactoryBot.define do
  factory :search_setting do
    sequence(:key) { |n| "setting_key_#{n}" }
    value { "test_value" }
    description { "Test setting description" }

    trait :rag_chunk_limit do
      key { "rag_chunk_limit" }
      value { "10" }
      description { "Maximum number of chunks to retrieve for RAG queries" }
    end
  end
end
