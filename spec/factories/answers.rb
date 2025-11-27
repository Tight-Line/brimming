# frozen_string_literal: true

FactoryBot.define do
  factory :answer do
    body { "This is an answer to the question. It provides helpful information to solve the problem." }
    association :user
    association :question
    is_correct { false }
    vote_score { 0 }

    trait :correct do
      is_correct { true }
    end

    trait :with_votes do
      transient do
        upvotes { 5 }
        downvotes { 1 }
      end

      after(:create) do |answer, evaluator|
        evaluator.upvotes.times do
          create(:vote, :upvote, answer: answer)
        end
        evaluator.downvotes.times do
          create(:vote, :downvote, answer: answer)
        end
        answer.recalculate_vote_score!
      end
    end
  end
end
