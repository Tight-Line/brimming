# frozen_string_literal: true

class Question < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :category
  has_many :answers, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { minimum: 10, maximum: 200 }
  validates :body, presence: true, length: { minimum: 20, maximum: 10_000 }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) }

  # Instance methods
  def author
    user
  end

  def answers_count
    answers.count
  end

  def has_correct_answer?
    answers.exists?(is_correct: true)
  end

  def correct_answer
    answers.find_by(is_correct: true)
  end

  def top_answers(limit = 10)
    answers.by_votes.limit(limit)
  end

  def owned_by?(other_user)
    user_id == other_user&.id
  end
end
