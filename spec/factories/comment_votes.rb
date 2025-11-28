# frozen_string_literal: true

FactoryBot.define do
  factory :comment_vote do
    association :user
    association :comment
  end
end
