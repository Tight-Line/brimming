# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    password { "password123" }
    avatar_url { nil }
    role { :user }

    trait :with_avatar do
      avatar_url { "https://example.com/avatars/#{username}.png" }
    end

    trait :moderator do
      role { :moderator }
    end

    trait :admin do
      role { :admin }
    end
  end
end
