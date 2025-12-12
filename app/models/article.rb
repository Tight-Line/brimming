# frozen_string_literal: true

class Article < ApplicationRecord
  CONTENT_TYPES = %w[markdown html pdf docx xlsx txt webpage].freeze

  # File extension to content type mapping
  FILE_EXTENSION_MAP = {
    ".pdf" => "pdf",
    ".doc" => "docx",
    ".docx" => "docx",
    ".xls" => "xlsx",
    ".xlsx" => "xlsx",
    ".html" => "html",
    ".htm" => "html"
  }.freeze

  # Virtual attribute for form input mode
  attr_accessor :input_mode

  # Associations
  belongs_to :user
  belongs_to :last_editor, class_name: "User", optional: true
  belongs_to :reader_provider, optional: true
  has_many :article_spaces, dependent: :destroy
  has_many :spaces, through: :article_spaces
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :chunks, as: :chunkable, dependent: :destroy
  has_many :article_votes, dependent: :destroy
  has_many :bookmarks, as: :bookmarkable, dependent: :destroy

  # File attachment for non-text formats (PDF, Word, etc.)
  has_one_attached :original_file

  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 200 }
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9-]+\z/,
                             message: "can only contain lowercase letters, numbers, and hyphens" }
  validates :content_type, presence: true, inclusion: { in: CONTENT_TYPES }
  validates :source_url, presence: true, if: :webpage_content?
  validate :source_url_is_valid_url, if: -> { source_url.present? }

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  before_validation :detect_content_type_from_file, if: :original_file_attached_changed?
  before_validation :set_default_content_type
  after_commit :schedule_embedding_generation, on: %i[create update], if: :embedding_generation_needed?

  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :orphaned, -> { active.left_joins(:article_spaces).where(article_spaces: { id: nil }) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_content_type, ->(type) { where(content_type: type) }

  # Instance methods
  def to_param
    slug
  end

  def deleted?
    deleted_at.present?
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def restore!
    update!(deleted_at: nil)
  end

  def orphaned?
    article_spaces.empty?
  end

  def text_content?
    %w[markdown html txt webpage].include?(content_type)
  end

  def binary_content?
    %w[pdf docx xlsx].include?(content_type)
  end

  def webpage_content?
    content_type == "webpage"
  end

  # Mark as edited by a user
  def mark_edited!(editor)
    update!(last_editor: editor, edited_at: Time.current)
  end

  # Check if the article is owned by the given user
  def owned_by?(user)
    return false unless user

    user_id == user.id
  end

  # View tracking
  def increment_views!
    increment!(:views_count)
  end

  # Voting methods (articles only support upvotes, no downvotes)
  def upvote_by(voter)
    vote = article_votes.find_or_initialize_by(user: voter)
    return if vote.persisted? # Already upvoted

    vote.value = 1
    vote.save!
    increment!(:vote_score)
  end

  def remove_vote_by(voter)
    vote = article_votes.find_by(user: voter)
    return unless vote

    vote.destroy!
    decrement!(:vote_score)
  end

  def vote_by(voter)
    article_votes.find_by(user: voter)
  end

  def upvoted_by?(voter)
    article_votes.exists?(user: voter)
  end

  def recalculate_vote_score!
    update!(vote_score: article_votes.count)
  end

  # Get display content type
  def display_content_type
    # All content types are validated, so this covers all possibilities
    {
      "markdown" => "Markdown",
      "html" => "HTML",
      "pdf" => "PDF",
      "docx" => "Word Document",
      "xlsx" => "Excel Spreadsheet",
      "txt" => "Plain Text",
      "webpage" => "Web Page"
    }[content_type]
  end

  private

  def generate_slug
    base_slug = title.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
    self.slug = base_slug

    # Ensure uniqueness
    counter = 1
    while Article.exists?(slug: slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end

  def detect_content_type_from_file
    # This callback is only called when original_file_attached_changed? is true,
    # which already checks original_file.attached?, so no guard needed here.
    filename = original_file.filename.to_s
    extension = File.extname(filename).downcase

    if FILE_EXTENSION_MAP.key?(extension)
      self.content_type = FILE_EXTENSION_MAP[extension]
    end
  end

  def original_file_attached_changed?
    # When a file is attached, blob and created_at are always present,
    # so no safe navigation needed.
    original_file.attached? && (new_record? || original_file.blob.created_at > 1.minute.ago)
  end

  def set_default_content_type
    self.content_type ||= "markdown"
  end

  def schedule_embedding_generation
    GenerateArticleEmbeddingJob.perform_later(self)
  end

  def embedding_generation_needed?
    return false unless EmbeddingService.available?

    # Generate chunks/embeddings if:
    # - No chunks yet, OR
    # - Title or body changed since last embedding, OR
    # - File was attached/changed (for binary content types)
    chunks.empty? ||
      (embedded_at.present? && (saved_change_to_title? || saved_change_to_body?)) ||
      original_file_attached_changed?
  end

  def source_url_is_valid_url
    uri = URI.parse(source_url)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      errors.add(:source_url, "must be a valid HTTP or HTTPS URL")
    end
  rescue URI::InvalidURIError
    errors.add(:source_url, "is not a valid URL")
  end
end
