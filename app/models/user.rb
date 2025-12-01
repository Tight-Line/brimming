# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  # Note: We use custom LDAP authentication instead of :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Enums (moderator is per-space via SpaceModerator, not a global role)
  enum :role, { user: 0, admin: 2 }, default: :user

  # Scopes
  scope :search, ->(query) {
    return none if query.blank?

    sanitized = "%#{sanitize_sql_like(query)}%"
    where("username ILIKE :q OR full_name ILIKE :q", q: sanitized)
      .order(:username)
      .limit(10)
  }

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
  has_many :space_publishers, dependent: :destroy
  has_many :published_spaces, through: :space_publishers, source: :space
  has_many :space_opt_outs, dependent: :destroy
  has_many :articles, dependent: :destroy

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

  # Returns true if the user is a publisher of any space
  def publisher?
    space_publishers.exists?
  end

  def can_publish?(space)
    admin? || space.moderators.include?(self) || space.publishers.include?(self)
  end

  # Returns all spaces the user can publish articles to
  def publishable_spaces
    return Space.all if admin?

    Space.where(id: moderated_spaces.select(:id))
         .or(Space.where(id: published_spaces.select(:id)))
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

  # True if this user authenticated via LDAP
  def ldap_user?
    provider == "ldap"
  end

  # Find or create a user from OmniAuth LDAP callback
  def self.from_omniauth(auth, ldap_server)
    email = auth.info.email
    uid = auth.uid
    dn = auth.extra&.raw_info&.dn

    # Try to find by provider+uid first, then by email
    user = find_by(provider: auth.provider, uid: uid)
    user ||= find_by(email: email)

    if user
      # Update existing user with LDAP info if not already set
      user.update!(
        provider: auth.provider,
        uid: uid,
        ldap_dn: dn,
        full_name: auth.info.name.presence || user.full_name
      )
    else
      # Create new user from LDAP data
      user = create!(
        provider: auth.provider,
        uid: uid,
        ldap_dn: dn,
        email: email,
        username: generate_unique_username(auth.info.nickname || email.split("@").first),
        full_name: auth.info.name,
        password: Devise.friendly_token[0, 20]
      )
    end

    user
  end

  # Generate a unique username from base name
  def self.generate_unique_username(base)
    base = base.gsub(/[^a-zA-Z0-9_]/, "_").first(25)
    username = base

    counter = 1
    while exists?(username: username)
      username = "#{base}_#{counter}"
      counter += 1
    end

    username
  end
end
