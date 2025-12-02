# frozen_string_literal: true

FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "Article Title #{n}" }
    body { "This is the article body content." }
    content_type { "markdown" }
    user

    trait :html do
      content_type { "html" }
      body { "<p>This is HTML content.</p>" }
    end

    trait :plain_text do
      content_type { "txt" }
      body { "Plain text content here." }
    end

    trait :pdf do
      content_type { "pdf" }
      body { nil }
    end

    trait :docx do
      content_type { "docx" }
      body { nil }
    end

    trait :xlsx do
      content_type { "xlsx" }
      body { nil }
    end

    trait :with_context do
      context { "This article provides guidance on best practices." }
    end

    trait :deleted do
      deleted_at { 1.day.ago }
    end

    trait :with_custom_slug do
      sequence(:slug) { |n| "custom-slug-#{n}" }
    end

    trait :edited do
      last_editor { association :user }
      edited_at { 1.hour.ago }
    end
  end
end
