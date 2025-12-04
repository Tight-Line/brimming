# frozen_string_literal: true

class FaqSuggestion < ApplicationRecord
  SOURCE_TYPES = %w[article upload manual rag].freeze
  SOURCE_TYPES_DISPLAY = {
    "article" => "Article",
    "upload" => "Uploaded Document",
    "manual" => "Manual Entry",
    "rag" => "Knowledge Base"
  }.freeze
  STATUSES = %w[pending approved rejected created].freeze

  belongs_to :space
  belongs_to :created_by, class_name: "User"

  validates :batch_id, presence: true
  validates :source_type, presence: true, inclusion: { in: SOURCE_TYPES }
  validates :question_text, presence: true, length: { minimum: 10, maximum: 200 }
  validates :question_body, length: { maximum: 5000 }, allow_blank: true
  validates :answer_text, presence: true, length: { minimum: 20, maximum: 10_000 }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :created, -> { where(status: "created") }
  scope :for_batch, ->(batch_id) { where(batch_id: batch_id) }
  scope :stale, -> { where("created_at < ?", 7.days.ago).where.not(status: "created") }

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  def created?
    status == "created"
  end

  def approve!
    update!(status: "approved")
  end

  def reject!
    update!(status: "rejected")
  end

  def mark_created!
    update!(status: "created")
  end

  # Parse source_context as JSON array of excerpts
  def source_excerpts
    return [] if source_context.blank?

    JSON.parse(source_context)
  rescue JSON::ParserError
    [ source_context ]
  end

  def source_excerpts=(excerpts)
    self.source_context = excerpts.to_json
  end

  def display_source_type
    SOURCE_TYPES_DISPLAY.fetch(source_type)
  end
end
