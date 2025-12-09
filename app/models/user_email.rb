# frozen_string_literal: true

class UserEmail < ApplicationRecord
  belongs_to :user

  # Validations
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :only_one_primary_per_user, if: :primary?

  # Callbacks
  before_validation :normalize_email
  before_create :generate_verification_token, unless: :verified?

  # Scopes
  scope :verified, -> { where(verified: true) }
  scope :unverified, -> { where(verified: false) }
  scope :primary, -> { where(primary: true) }

  # Find a user by any of their verified emails
  def self.find_user_by_verified_email(email)
    user_email = verified.find_by("LOWER(email) = LOWER(?)", email)
    user_email&.user
  end

  # Find a user email record by email (verified or not)
  def self.find_by_email(email)
    find_by("LOWER(email) = LOWER(?)", email)
  end

  # Mark this email as verified
  def verify!
    update!(
      verified: true,
      verified_at: Time.current,
      verification_token: nil
    )
  end

  # Mark this email as the primary email for the user
  def mark_as_primary!
    return if primary?
    raise "Cannot set unverified email as primary" unless verified?

    transaction do
      # Remove primary from other emails
      user.user_emails.where.not(id: id).update_all(primary: false)
      # Set this one as primary
      update!(primary: true)
      # Sync to user.email for Devise compatibility
      user.update!(email: email)
    end
  end

  # Generate a new verification token and send verification email
  def send_verification!
    generate_verification_token
    save!
    UserEmailMailer.verification_email(self).deliver_later
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def generate_verification_token
    self.verification_token = SecureRandom.urlsafe_base64(32)
  end

  def only_one_primary_per_user
    return unless user

    existing_primary = user.user_emails.primary.where.not(id: id).exists?
    errors.add(:primary, "email already exists for this user") if existing_primary
  end
end
