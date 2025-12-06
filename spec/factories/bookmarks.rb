# frozen_string_literal: true

FactoryBot.define do
  factory :bookmark do
    association :user
    association :bookmarkable, factory: :question

    trait :for_question do
      association :bookmarkable, factory: :question
    end

    trait :for_answer do
      association :bookmarkable, factory: :answer
    end

    trait :for_comment do
      association :bookmarkable, factory: :comment
    end

    trait :for_article do
      association :bookmarkable, factory: :article
    end

    trait :with_notes do
      notes { "This is a useful bookmark" }
    end
  end
end
