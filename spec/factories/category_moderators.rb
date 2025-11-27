# frozen_string_literal: true

FactoryBot.define do
  factory :category_moderator do
    association :category
    association :user
  end
end
