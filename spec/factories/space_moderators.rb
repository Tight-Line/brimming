# frozen_string_literal: true

FactoryBot.define do
  factory :space_moderator do
    association :space
    association :user
  end
end
