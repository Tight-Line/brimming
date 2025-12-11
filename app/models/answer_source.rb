# frozen_string_literal: true

class AnswerSource < ApplicationRecord
  SOURCE_TYPES = %w[Article Question Chunk Upload].freeze
  SOURCE_TYPES_DISPLAY = {
    "Article" => "Article",
    "Question" => "Question",
    "Chunk" => "Content Chunk",
    "Upload" => "Uploaded Document"
  }.freeze

  belongs_to :answer

  validates :source_type, presence: true, inclusion: { in: SOURCE_TYPES }
  validates :source_excerpt, presence: true

  # Polymorphic-like association without strict foreign key
  # source_id can be nil for uploads (which are extracted text, not persisted)
  def source
    return nil if source_id.blank?

    source_type.constantize.find_by(id: source_id)
  end

  def source=(record)
    if record.nil?
      self.source_type = nil
      self.source_id = nil
    else
      self.source_type = record.class.name
      self.source_id = record.id
    end
  end

  def display_source_type
    SOURCE_TYPES_DISPLAY.fetch(source_type)
  end

  # Truncated excerpt for display
  def excerpt_preview(length: 200)
    return "" if source_excerpt.blank?

    if source_excerpt.length <= length
      source_excerpt
    else
      "#{source_excerpt[0, length]}..."
    end
  end
end
