# frozen_string_literal: true

class Question < ApplicationRecord
  # Vector embedding for semantic search (via neighbor gem)
  has_neighbors :embedding

  # Constants
  MAX_TAGS = 5

  # Associations
  belongs_to :user
  belongs_to :space
  belongs_to :last_editor, class_name: "User", optional: true
  belongs_to :embedding_provider, optional: true
  has_many :answers, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :question_votes, dependent: :destroy
  has_many :question_tags, dependent: :destroy
  has_many :tags, through: :question_tags

  # Validations
  validates :title, presence: true, length: { minimum: 10, maximum: 200 }
  validates :body, presence: true, length: { minimum: 20, maximum: 10_000 }
  validates :slug, presence: true,
                   uniqueness: { case_sensitive: false },
                   # TODO: i18n
                   format: { with: /\A[a-z0-9-]+\z/,
                             message: "can only contain lowercase letters, numbers, and hyphens" }
  validate :tags_count_within_limit
  validate :tags_belong_to_same_space

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  after_commit :schedule_embedding_generation, on: %i[create update], if: :embedding_generation_needed?

  # Scopes
  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_space, ->(space) { where(space: space) }

  # Instance methods
  def to_param
    slug
  end

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

  def edited?
    edited_at.present?
  end

  def record_edit!(editor)
    update!(edited_at: Time.current, last_editor: editor)
  end

  def increment_views!
    increment!(:views_count)
  end

  # Voting methods
  def upvote_by(voter)
    vote = question_votes.find_or_initialize_by(user: voter)
    old_value = vote.value || 0
    vote.value = 1
    vote.save!
    update_vote_score!(1 - old_value)
  end

  def downvote_by(voter)
    vote = question_votes.find_or_initialize_by(user: voter)
    old_value = vote.value || 0
    vote.value = -1
    vote.save!
    update_vote_score!(-1 - old_value)
  end

  def remove_vote_by(voter)
    vote = question_votes.find_by(user: voter)
    return unless vote

    old_value = vote.value
    vote.destroy!
    update_vote_score!(-old_value)
  end

  def vote_by(voter)
    question_votes.find_by(user: voter)
  end

  def recalculate_vote_score!
    update!(vote_score: question_votes.sum(:value))
  end

  def deleted?
    deleted_at.present?
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  # Tag helpers
  def tag_names
    tags.pluck(:name)
  end

  # Update the PostgreSQL full-text search vector.
  # Called automatically by trigger when title/body change,
  # but must be called manually when answers are added/modified/deleted.
  def refresh_search_vector!
    answer_text = answers.not_deleted.pluck(:body).join(" ")

    self.class.where(id: id).update_all([
      "search_vector = setweight(to_tsvector('english', COALESCE(?, '')), 'A') || " \
      "setweight(to_tsvector('english', COALESCE(?, '')), 'B') || " \
      "setweight(to_tsvector('english', COALESCE(?, '')), 'C')",
      title, body, answer_text
    ])
  end

  private

  def schedule_embedding_generation
    GenerateQuestionEmbeddingJob.perform_later(self)
  end

  def embedding_generation_needed?
    return false unless EmbeddingService.available?

    # Generate embedding if:
    # - No embedding yet, OR
    # - Title or body changed since last embedding
    embedding.nil? || (embedded_at.present? && (saved_change_to_title? || saved_change_to_body?))
  end

  # TODO: i18n
  def tags_count_within_limit
    return if tags.size <= MAX_TAGS

    errors.add(:tags, "cannot exceed #{MAX_TAGS}")
  end

  # TODO: i18n
  def tags_belong_to_same_space
    return if tags.empty?

    invalid_tags = tags.reject { |tag| tag.space_id == space_id }
    return if invalid_tags.empty?

    errors.add(:tags, "must belong to the same space as the question")
  end

  def update_vote_score!(delta)
    increment!(:vote_score, delta)
  end

  def generate_slug
    base_slug = title.downcase
                     .gsub(/[^a-z0-9\s-]/, "")  # Remove special characters
                     .gsub(/\s+/, "-")           # Replace spaces with hyphens
                     .gsub(/-+/, "-")            # Collapse multiple hyphens
                     .gsub(/^-|-$/, "")          # Remove leading/trailing hyphens
                     .truncate(80, omission: "") # Limit length

    # Ensure uniqueness by appending a number if needed
    slug_candidate = base_slug
    counter = 1

    while Question.exists?(slug: slug_candidate)
      slug_candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = slug_candidate
  end
end
