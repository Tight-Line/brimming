# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  # Note: We use custom LDAP authentication instead of :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Override Devise to authenticate via UserEmail table
  # This allows users to log in with any verified email address
  def self.find_for_database_authentication(warden_conditions)
    email = warden_conditions[:email]&.downcase&.strip
    return nil if email.blank?

    # Look up user by verified email in user_emails table
    user_email = UserEmail.verified.find_by("LOWER(email) = ?", email)
    return user_email.user if user_email

    # Fall back to users.email for backwards compatibility during migration
    find_by("LOWER(email) = ?", email)
  end

  # Override Devise to find users for password reset by any verified email
  def self.find_for_authentication(warden_conditions)
    find_for_database_authentication(warden_conditions)
  end

  # Override Devise to find users for password reset by verified email
  # This is called by send_reset_password_instructions
  def self.find_first_by_auth_conditions(tainted_conditions, _opts = {})
    conditions = tainted_conditions.dup
    email = conditions.delete(:email)&.downcase&.strip
    return nil if email.blank?

    # Look up user by verified email in user_emails table
    user_email = UserEmail.verified.find_by("LOWER(email) = ?", email)
    return user_email.user if user_email

    # Fall back to users.email for backwards compatibility during migration
    find_by("LOWER(email) = ?", email)
  end

  # Enums (moderator is per-space via SpaceModerator, not a global role)
  # system role is for non-human accounts (e.g., "Helpful Robot" for AI-generated content)
  enum :role, { user: 0, admin: 2, system: 3 }, default: :user

  # Scopes
  scope :search, ->(query) {
    return none if query.blank?

    sanitized = "%#{sanitize_sql_like(query)}%"
    where("username ILIKE :q OR full_name ILIKE :q", q: sanitized)
      .order(:username)
      .limit(10)
  }

  # Avatar attachment via Active Storage
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 100, 100 ]
    attachable.variant :medium, resize_to_limit: [ 200, 200 ]
  end

  # Associations
  has_many :user_emails, dependent: :destroy
  has_one :primary_user_email, -> { where(primary: true) }, class_name: "UserEmail", inverse_of: :user
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
  has_many :bookmarks, dependent: :destroy

  # Validations (email handled by Devise's :validatable module)
  validates :username, presence: true,
                       uniqueness: { case_sensitive: false },
                       length: { minimum: 3, maximum: 30 },
                       format: { with: /\A[a-zA-Z0-9_]+\z/,
                                 message: "can only contain letters, numbers, and underscores" }
  validates :role, presence: true
  validates :avatar, content_type: { in: %w[image/png image/jpeg image/gif image/webp],
                                     message: "must be a PNG, JPEG, GIF, or WebP image" },
                     size: { less_than: 2.megabytes,
                             message: "must be less than 2MB" },
                     if: -> { avatar.attached? }

  # Callbacks
  after_create :create_primary_user_email

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

  def system?
    role == "system"
  end

  # Returns the system robot user for AI-generated content
  def self.robot
    find_by(role: :system)
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

  # Email management methods

  # Add a new email address (will need verification)
  def add_email(email_address)
    user_emails.create(email: email_address, primary: false, verified: false)
  end

  # Check if user has a verified email matching the given address
  def has_verified_email?(email_address)
    user_emails.verified.exists?([ "LOWER(email) = LOWER(?)", email_address ])
  end

  # Check if user has this email (verified or not)
  def has_email?(email_address)
    user_emails.exists?([ "LOWER(email) = LOWER(?)", email_address ])
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

  # Returns all spaces the user is subscribed to (manual + LDAP, excluding opt-outs)
  # This is the comprehensive list used for feed filtering and UI display
  def all_subscribed_spaces
    manual_space_ids = subscribed_spaces.pluck(:id)
    ldap_space_ids = ldap_subscribed_space_ids
    Space.where(id: (manual_space_ids + ldap_space_ids).uniq)
  end

  # Returns true if user is subscribed to the space (via manual or LDAP)
  def subscribed_to?(space)
    subscribed_spaces.include?(space) || ldap_subscribed_space_ids.include?(space.id)
  end

  # Returns space IDs from LDAP group mappings (excluding opted-out spaces)
  def ldap_subscribed_space_ids
    return [] unless ldap_user? && ldap_dn.present?

    # Get all LDAP group mappings from the user's LDAP server
    # Note: This relies on the ldap_server_id being available, which it may not be
    # For now, we check all enabled LDAP servers' mappings
    opted_out_ids = space_opt_outs.pluck(:space_id)

    LdapGroupMapping
      .joins(:ldap_server)
      .where(ldap_servers: { enabled: true })
      .flat_map { |mapping| mapping.spaces.pluck(:id) }
      .uniq - opted_out_ids
  end

  # Returns the LDAP group mapping that grants subscription to a space, or nil
  def ldap_subscription_for(space)
    return nil unless ldap_user? && ldap_dn.present?
    return nil if space_opt_outs.exists?(space: space)

    LdapGroupMapping
      .joins(:ldap_server, :spaces)
      .where(ldap_servers: { enabled: true })
      .where(spaces: { id: space.id })
      .first
  end

  # Custom error for unverified email during LDAP login
  class UnverifiedEmailError < StandardError
    attr_reader :email

    def initialize(email)
      @email = email
      super("Email address #{email} must be verified before logging in")
    end
  end

  # Find or create a user from OmniAuth LDAP callback
  # Returns the user on success
  # Raises UnverifiedEmailError if email exists but is unverified
  def self.from_omniauth(auth, ldap_server)
    email = auth.info.email&.downcase&.strip
    uid = auth.uid
    dn = auth.extra&.raw_info&.dn

    # Try to find by provider+uid first
    user = find_by(provider: auth.provider, uid: uid)

    # If not found by provider/uid, try to find by verified email
    unless user
      user_email = UserEmail.find_by_email(email)
      if user_email
        # Email exists in system
        if user_email.verified?
          user = user_email.user
        else
          # Email exists but is unverified - cannot log in
          raise UnverifiedEmailError, email
        end
      end
    end

    if user
      # Update existing user with LDAP info
      user.update!(
        provider: auth.provider,
        uid: uid,
        ldap_dn: dn,
        full_name: auth.info.name.presence || user.full_name
      )

      # Ensure the LDAP email is in their email list (verified)
      unless user.has_email?(email)
        user.user_emails.create!(email: email, primary: false, verified: true, verified_at: Time.current)
      end
    else
      # Create new user from LDAP data
      # The after_create callback will automatically create the primary UserEmail record
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

  private

  # Create a primary UserEmail entry for new users
  def create_primary_user_email
    return if email.blank?
    return if user_emails.exists?(email: email.downcase)

    user_emails.create!(
      email: email,
      primary: true,
      verified: true,
      verified_at: Time.current
    )
  end
end
