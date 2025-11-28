# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    body { "This is a helpful comment on the content." }
    association :user
    association :commentable, factory: :question
    vote_score { 0 }

    trait :on_question do
      association :commentable, factory: :question
    end

    trait :on_answer do
      association :commentable, factory: :answer
    end

    trait :reply do
      association :parent_comment, factory: :comment
      commentable { parent_comment.commentable }
    end

    trait :with_votes do
      transient do
        votes_count { 5 }
      end

      after(:create) do |comment, evaluator|
        evaluator.votes_count.times do
          create(:comment_vote, comment: comment)
        end
        comment.update!(vote_score: evaluator.votes_count)
      end
    end
  end
end
