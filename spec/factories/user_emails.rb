# frozen_string_literal: true

FactoryBot.define do
  factory :user_email do
    user
    sequence(:email) { |n| "user_email_#{n}@example.com" }
    primary { false }
    verified { false }
    verified_at { nil }
    verification_token { SecureRandom.urlsafe_base64(32) }

    trait :primary do
      primary { true }
      verified { true }
      verified_at { Time.current }
      verification_token { nil }
    end

    trait :verified do
      verified { true }
      verified_at { Time.current }
      verification_token { nil }
    end

    trait :unverified do
      verified { false }
      verified_at { nil }
      # verification_token is set by before_create callback
    end
  end
end
