# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Enums (moderator is per-space via SpaceModerator, not a global role)
  enum :role, { user: 0, admin: 2 }, default: :user

  # Associations
  has_many :questions, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :question_votes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :comment_votes, dependent: :destroy
  has_many :space_subscriptions, dependent: :destroy
  has_many :subscribed_spaces, through: :space_subscriptions, source: :space
  has_many :space_moderators, dependent: :destroy
  has_many :moderated_spaces, through: :space_moderators, source: :space

  # Validations (email handled by Devise's :validatable module)
  validates :username, presence: true,
                       uniqueness: { case_sensitive: false },
                       length: { minimum: 3, maximum: 30 },
                       format: { with: /\A[a-zA-Z0-9_]+\z/,
                                 message: "can only contain letters, numbers, and underscores" }
  validates :role, presence: true

  # Instance methods
  def to_param
    username
  end

  def display_name
    full_name.presence || username
  end

  def has_solved_answer?
    answers.exists?(is_correct: true)
  end

  def admin?
    role == "admin"
  end

  # Returns true if the user is a moderator of any space
  def moderator?
    space_moderators.exists?
  end

  def can_moderate?(space)
    admin? || space.moderators.include?(self)
  end

  # Stats for gamification
  def questions_count
    questions.count
  end

  def answers_count
    answers.count
  end

  # Answers marked as solved by a moderator
  def solved_answers_count
    answers.where(is_correct: true).count
  end

  # Answers that are the highest-voted for their question
  # NOTE: Uses PostgreSQL-specific DISTINCT ON syntax (not compatible with MySQL/SQLite)
  def best_answers_count
    best_answer_ids = Answer.select("DISTINCT ON (question_id) id")
                            .order("question_id, vote_score DESC, created_at ASC")

    answers.where(id: best_answer_ids).count
  end

  def comments_count
    comments.count
  end

  # Karma calculation:
  # +5 for each question asked
  # +10 for each answer given
  # +15 bonus for each solved answer (marked correct by moderator)
  # +1 for each upvote received on questions
  # +1 for each upvote received on answers
  # +1 for each upvote received on comments
  def karma
    question_karma = questions_count * 5
    answer_karma = answers_count * 10
    solved_answer_karma = solved_answers_count * 15
    question_vote_karma = questions.sum(:vote_score)
    answer_vote_karma = answers.sum(:vote_score)
    comment_vote_karma = comments.sum(:vote_score)

    question_karma + answer_karma + solved_answer_karma +
      question_vote_karma + answer_vote_karma + comment_vote_karma
  end

end
