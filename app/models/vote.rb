# frozen_string_literal: true

class Vote < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :answer

  # Validations
  validates :value, presence: true, inclusion: { in: [ -1, 1 ] }
  validates :user_id, uniqueness: { scope: :answer_id, message: "has already voted on this answer" }

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
