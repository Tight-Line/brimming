# frozen_string_literal: true

FactoryBot.define do
  factory :chunk do
    association :chunkable, factory: :question
    sequence(:chunk_index)
    content { "This is chunk content for testing purposes." }
    token_count { 10 }
    metadata { {} }

    trait :embedded do
      association :embedding_provider, factory: [ :embedding_provider, :openai ]
      embedding { Array.new(1536) { rand(-1.0..1.0) } }
      embedded_at { Time.current }
    end

    trait :unembedded do
      embedding { nil }
      embedded_at { nil }
      embedding_provider { nil }
    end

    trait :with_source_metadata do
      metadata { { "source_type" => "answer", "source_id" => 123, "position" => "middle" } }
    end
  end
end
