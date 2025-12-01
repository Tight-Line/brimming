# frozen_string_literal: true

class Comment < ApplicationRecord
  # Maximum nesting depth for comment replies
  MAX_DEPTH = 3

  # Associations
  belongs_to :user
  belongs_to :commentable, polymorphic: true
  belongs_to :parent_comment, class_name: "Comment", optional: true
  belongs_to :last_editor, class_name: "User", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_comment_id, dependent: :destroy
  has_many :comment_votes, dependent: :destroy

  # Validations
  validates :body, presence: true, length: { minimum: 1, maximum: 2000 }

  # Scopes
  scope :top_level, -> { where(parent_comment_id: nil) }
  scope :recent, -> { order(created_at: :asc) }
  scope :by_votes, -> { order(vote_score: :desc, created_at: :asc) }
  scope :not_deleted, -> { where(deleted_at: nil) }

  # Instance methods
  def author
    user
  end

  def edited?
    edited_at.present?
  end

  def record_edit!(editor)
    update!(edited_at: Time.current, last_editor: editor)
  end

  def upvote_by(voter)
    return if comment_votes.exists?(user: voter)

    comment_votes.create!(user: voter)
    increment!(:vote_score)
  end

  def remove_vote_by(voter)
    vote = comment_votes.find_by(user: voter)
    return unless vote

    vote.destroy!
    decrement!(:vote_score)
  end

  def voted_by?(voter)
    comment_votes.exists?(user: voter)
  end

  def owned_by?(other_user)
    user_id == other_user&.id
  end

  def reply?
    parent_comment_id.present?
  end

  def depth
    return 0 unless parent_comment

    1 + parent_comment.depth
  end

  def allows_replies?
    depth < MAX_DEPTH && !deleted?
  end

  def deleted?
    deleted_at.present?
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  # Returns the space this comment belongs to (through question, answer, or article)
  # For articles, returns the first space (if any) - may return nil for orphaned articles
  def space
    case commentable_type
    when "Question" then commentable.space
    when "Answer" then commentable.question.space
    when "Article" then commentable.spaces.first
    else
      raise "Unknown commentable_type: #{commentable_type}"
    end
  end

  # Returns the root question ID this comment belongs to (for search indexing)
  # Returns nil for article comments
  def root_question_id
    case commentable_type
    when "Question" then commentable_id
    when "Answer" then commentable.question_id
    else nil
    end
  end

  # Returns the root question this comment belongs to
  # Returns nil for article comments
  def root_question
    case commentable_type
    when "Question" then commentable
    when "Answer" then commentable.question
    else nil
    end
  end

  # Returns the article if this is an article comment
  def article
    commentable if commentable_type == "Article"
  end
end
