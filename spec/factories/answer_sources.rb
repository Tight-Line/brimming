# frozen_string_literal: true

FactoryBot.define do
  factory :answer_source do
    association :answer
    source_type { "Article" }
    source_id { nil }
    source_title { "Test Source Title" }
    source_excerpt { "This is a test excerpt from the source material." }
    citation_number { 1 }

    trait :with_article do
      transient do
        article { nil }
      end

      after(:build) do |answer_source, evaluator|
        source_article = evaluator.article || create(:article, user: answer_source.answer.user)
        answer_source.source_type = "Article"
        answer_source.source_id = source_article.id
        answer_source.source_title = source_article.title
      end
    end

    trait :with_question do
      transient do
        source_question { nil }
      end

      after(:build) do |answer_source, evaluator|
        source_q = evaluator.source_question || create(:question, user: answer_source.answer.user)
        answer_source.source_type = "Question"
        answer_source.source_id = source_q.id
        answer_source.source_title = source_q.title
      end
    end
  end
end
