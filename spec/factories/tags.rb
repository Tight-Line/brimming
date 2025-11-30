# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "tag-#{n}" }
    association :space
    description { "A description for this tag" }

    trait :with_questions do
      transient do
        questions_count { 3 }
      end

      after(:create) do |tag, evaluator|
        create_list(:question, evaluator.questions_count, space: tag.space, tags: [ tag ])
      end
    end
  end
end
