# frozen_string_literal: true

FactoryBot.define do
  factory :vote do
    association :user
    association :answer
    value { 1 }

    trait :upvote do
      value { 1 }
    end

    trait :downvote do
      value { -1 }
    end
  end
end
