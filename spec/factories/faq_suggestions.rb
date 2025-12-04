# frozen_string_literal: true

FactoryBot.define do
  factory :faq_suggestion do
    space
    association :created_by, factory: :user
    batch_id { SecureRandom.uuid }
    source_type { "article" }
    source_context { [ { article_id: 1, title: "Test Article" } ].to_json }
    sequence(:question_text) { |n| "What is the best practice for feature #{n}?" }
    question_body { "I'm trying to implement this feature and want to follow best practices.\n\nWhat should I keep in mind?" }
    answer_text { "The best practice is to follow the established guidelines and documentation. Here are the key points to consider when implementing this feature." }
    status { "pending" }

    trait :from_article do
      source_type { "article" }
      source_context { [ { article_id: 1, title: "Test Article" } ].to_json }
    end

    trait :from_rag do
      source_type { "rag" }
      source_context { [ { chunk_id: 1, excerpt: "Some relevant content..." } ].to_json }
    end

    trait :from_topic do
      source_type { "manual" }
      source_context { [ { topic: "How to deploy applications" } ].to_json }
    end

    trait :pending do
      status { "pending" }
    end

    trait :approved do
      status { "approved" }
    end

    trait :rejected do
      status { "rejected" }
    end

    trait :created do
      status { "created" }
    end
  end
end
