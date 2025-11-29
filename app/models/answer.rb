# frozen_string_literal: true

class Answer < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :question
  belongs_to :last_editor, class_name: "User", optional: true
  has_many :votes, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  # Validations
  validates :body, presence: true, length: { minimum: 10, maximum: 10_000 }

  # Scopes
  scope :by_votes, -> { order(vote_score: :desc, created_at: :asc) }
  scope :correct, -> { where(is_correct: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def author
    user
  end

  def mark_as_correct!
    transaction do
      # Unmark any existing correct answer for this question
      question.answers.where(is_correct: true).update_all(is_correct: false)
      update!(is_correct: true)
    end
  end

  def unmark_as_correct!
    update!(is_correct: false)
  end

  def upvote_by(voter)
    vote = votes.find_or_initialize_by(user: voter)
    old_value = vote.value || 0
    vote.value = 1
    vote.save!
    update_vote_score!(1 - old_value)
  end

  def downvote_by(voter)
    vote = votes.find_or_initialize_by(user: voter)
    old_value = vote.value || 0
    vote.value = -1
    vote.save!
    update_vote_score!(-1 - old_value)
  end

  def remove_vote_by(voter)
    vote = votes.find_by(user: voter)
    return unless vote

    old_value = vote.value
    vote.destroy!
    update_vote_score!(-old_value)
  end

  def vote_by(voter)
    votes.find_by(user: voter)
  end

  def owned_by?(other_user)
    user_id == other_user&.id
  end

  def edited?
    edited_at.present?
  end

  def record_edit!(editor)
    update!(edited_at: Time.current, last_editor: editor)
  end

  def recalculate_vote_score!
    update!(vote_score: votes.sum(:value))
  end

  def deleted?
    deleted_at.present?
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def space
    question.space
  end

  private

  def update_vote_score!(delta)
    increment!(:vote_score, delta)
  end
end
