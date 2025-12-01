# frozen_string_literal: true

class ArticleVote < ApplicationRecord
  # Articles only support upvotes (no downvotes)

  # Associations
  belongs_to :user
  belongs_to :article

  # Validations - only value of 1 (upvote) allowed
  validates :value, presence: true, inclusion: { in: [ 1 ] }
  validates :user_id, uniqueness: { scope: :article_id, message: "has already voted on this article" }

  # Instance methods
  def upvote?
    value == 1
  end
end
