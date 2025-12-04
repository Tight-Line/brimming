# frozen_string_literal: true

FactoryBot.define do
  factory :question_source do
    question
    source_type { "Article" }
    source_id { nil }
    source_excerpt { "This is the relevant excerpt from the source material that inspired this Q&A." }

    trait :from_article do
      source_type { "Article" }
      source_id { nil } # Will be set in tests if needed
    end

    trait :from_chunk do
      source_type { "Chunk" }
      source_id { nil }
    end

    trait :from_upload do
      source_type { "Upload" }
      source_id { nil }
    end
  end
end
