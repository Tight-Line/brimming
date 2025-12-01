# frozen_string_literal: true

FactoryBot.define do
  factory :article_vote do
    user
    article
    value { 1 } # Articles only support upvotes
  end
end
