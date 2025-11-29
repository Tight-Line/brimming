# frozen_string_literal: true

FactoryBot.define do
  factory :space do
    sequence(:name) { |n| "Space #{n}" }
    sequence(:slug) { |n| "space-#{n}" }
    description { "A description for this space" }

    trait :without_description do
      description { nil }
    end
  end
end
