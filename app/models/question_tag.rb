# frozen_string_literal: true

class QuestionTag < ApplicationRecord
  # Associations
  belongs_to :question
  belongs_to :tag, counter_cache: :questions_count

  # Validations
  validates :question_id, uniqueness: {
    scope: :tag_id,
    # TODO: i18n
    message: "already has this tag"
  }
  validate :tag_belongs_to_same_space

  private

  # TODO: i18n
  def tag_belongs_to_same_space
    return if question.blank? || tag.blank?
    return if question.space_id == tag.space_id

    errors.add(:tag, "must belong to the same space as the question")
  end
end
