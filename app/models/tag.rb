# frozen_string_literal: true

class Tag < ApplicationRecord
  # Associations
  belongs_to :space
  has_many :question_tags, dependent: :destroy
  has_many :questions, through: :question_tags

  # Validations
  validates :name, presence: true,
                   length: { minimum: 1, maximum: 50 },
                   uniqueness: { scope: :space_id, case_sensitive: false },
                   format: {
                     # TODO: i18n
                     with: /\A[a-z0-9][a-z0-9\-.]*\z/,
                     message: "can only contain lowercase letters, numbers, hyphens, and periods"
                   }
  validates :slug, presence: true,
                   uniqueness: { scope: :space_id, case_sensitive: false },
                   format: {
                     # TODO: i18n
                     with: /\A[a-z0-9-]+\z/,
                     message: "can only contain lowercase letters, numbers, and hyphens"
                   }
  validates :description, length: { maximum: 500 }

  # Callbacks
  before_validation :normalize_name
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Scopes
  scope :alphabetical, -> { order(:name) }
  scope :popular, -> { order(questions_count: :desc) }
  scope :search, ->(query) {
    return none if query.blank?

    sanitized = "#{sanitize_sql_like(query.downcase)}%"
    where("LOWER(name) LIKE :q OR LOWER(slug) LIKE :q", q: sanitized)
      .order(:name)
      .limit(10)
  }

  # Instance methods
  def to_param
    slug
  end

  def display_name
    name
  end

  private

  def normalize_name
    self.name = name&.strip&.downcase
  end

  def generate_slug
    self.slug = name.downcase
                    .gsub(/[^a-z0-9\-.]/, "-")
                    .gsub(/-+/, "-")
                    .gsub(/^-|-$/, "")
  end
end
