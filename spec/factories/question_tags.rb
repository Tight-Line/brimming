# frozen_string_literal: true

FactoryBot.define do
  factory :question_tag do
    question
    tag

    trait :same_space do
      after(:build) do |question_tag|
        # Ensure tag is in the same space as the question
        question_tag.tag.update!(space: question_tag.question.space) if question_tag.tag.space_id != question_tag.question.space_id
      end
    end
  end
end
