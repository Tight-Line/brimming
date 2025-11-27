# frozen_string_literal: true

class User < ApplicationRecord
  # Enums
  enum :role, { user: 0, moderator: 1, admin: 2 }, default: :user

  # Associations
  has_many :questions, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :votes, dependent: :destroy

  # Validations
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true,
                       uniqueness: { case_sensitive: false },
                       length: { minimum: 3, maximum: 30 },
                       format: { with: /\A[a-zA-Z0-9_]+\z/,
                                 message: "can only contain letters, numbers, and underscores" }
  validates :role, presence: true

  # Callbacks
  before_validation :normalize_email

  # Instance methods
  def display_name
    username
  end

  def admin?
    role == "admin"
  end

  def moderator?
    role == "moderator"
  end

  def can_moderate?(category)
    admin? || category.moderators.include?(self)
  end

  # Stats for gamification
  def questions_count
    questions.count
  end

  def answers_count
    answers.count
  end

  def best_answers_count
    answers.where(is_correct: true).count
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end
end
