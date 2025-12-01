# frozen_string_literal: true

class Space < ApplicationRecord
  # Associations
  has_many :questions, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :space_moderators, dependent: :destroy
  has_many :moderators, through: :space_moderators, source: :user
  has_many :space_publishers, dependent: :destroy
  has_many :publishers, through: :space_publishers, source: :user
  has_many :space_subscriptions, dependent: :destroy
  has_many :subscribers, through: :space_subscriptions, source: :user
  has_many :article_spaces, dependent: :destroy
  has_many :articles, through: :article_spaces

  # Validations
  validates :name, presence: true,
                   uniqueness: { case_sensitive: false },
                   length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true,
                   uniqueness: { case_sensitive: false },
                   # TODO: i18n
                   format: { with: /\A[a-z0-9-]+\z/,
                             message: "can only contain lowercase letters, numbers, and hyphens" }
  validates :description, length: { maximum: 1000 }

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Scopes
  scope :alphabetical, -> { order(:name) }

  # Instance methods
  def to_param
    slug
  end

  def questions_count
    questions.count
  end

  def add_moderator(user)
    moderators << user unless moderators.include?(user)
  end

  def remove_moderator(user)
    moderators.delete(user)
  end

  def moderator?(user)
    moderators.include?(user)
  end

  def add_publisher(user)
    publishers << user unless publishers.include?(user)
  end

  def remove_publisher(user)
    publishers.delete(user)
  end

  def publisher?(user)
    publishers.include?(user)
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
  end
end
