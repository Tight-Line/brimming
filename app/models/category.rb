# frozen_string_literal: true

class Category < ApplicationRecord
  # Associations
  has_many :questions, dependent: :destroy
  has_many :category_moderators, dependent: :destroy
  has_many :moderators, through: :category_moderators, source: :user
  has_many :category_subscriptions, dependent: :destroy
  has_many :subscribers, through: :category_subscriptions, source: :user

  # Validations
  validates :name, presence: true,
                   uniqueness: { case_sensitive: false },
                   length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true,
                   uniqueness: { case_sensitive: false },
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

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
  end
end
