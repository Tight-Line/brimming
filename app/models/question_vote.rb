# frozen_string_literal: true

class QuestionVote < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :question

  # Validations
  validates :value, presence: true, inclusion: { in: [ -1, 1 ] }
  validates :user_id, uniqueness: { scope: :question_id, message: "has already voted on this question" }

  # Scopes
  scope :upvotes, -> { where(value: 1) }
  scope :downvotes, -> { where(value: -1) }

  # Instance methods
  def upvote?
    value == 1
  end

  def downvote?
    value == -1
  end
end
