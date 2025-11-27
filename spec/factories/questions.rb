# frozen_string_literal: true

FactoryBot.define do
  factory :question do
    sequence(:title) { |n| "Question #{n}: How do I solve this problem?" }
    body { "This is the body of my question. It contains enough detail to meet the minimum length requirement for questions." }
    association :user
    association :category

    trait :with_answers do
      transient do
        answers_count { 3 }
      end

      after(:create) do |question, evaluator|
        create_list(:answer, evaluator.answers_count, question: question)
      end
    end
  end
end
