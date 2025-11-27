# frozen_string_literal: true

class CommentVote < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :comment

  # Validations
  validates :user_id, uniqueness: { scope: :comment_id, message: "has already voted on this comment" }
end
