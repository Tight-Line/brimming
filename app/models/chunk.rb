# frozen_string_literal: true

class Chunk < ApplicationRecord
  # Enable pgvector nearest neighbor search
  has_neighbors :embedding

  # Associations
  belongs_to :chunkable, polymorphic: true
  belongs_to :embedding_provider, optional: true

  # Validations
  validates :content, presence: true
  validates :chunk_index, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :chunk_index, uniqueness: { scope: [ :chunkable_type, :chunkable_id ],
                                        message: "must be unique within the parent document" }

  # Scopes
  scope :ordered, -> { order(:chunk_index) }
  scope :embedded, -> { where.not(embedded_at: nil) }
  scope :unembedded, -> { where(embedded_at: nil) }
  scope :for_chunkable, ->(chunkable) { where(chunkable: chunkable) }

  # Check if chunk has been embedded
  def embedded?
    embedded_at.present? && embedding.present?
  end

  # Mark chunk as needing re-embedding
  def mark_stale!
    update!(embedded_at: nil, embedding: nil)
  end

  # Set the embedding vector and mark as embedded
  def set_embedding!(vector, provider:)
    update!(
      embedding: vector,
      embedded_at: Time.current,
      embedding_provider: provider
    )
  end

  # Metadata accessors for source information
  def source_type
    metadata["source_type"]
  end

  def source_id
    metadata["source_id"]
  end

  def position
    metadata["position"]
  end
end
