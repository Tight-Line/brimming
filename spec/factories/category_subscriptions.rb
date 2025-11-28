# frozen_string_literal: true

FactoryBot.define do
  factory :category_subscription do
    association :user
    association :category
  end
end
