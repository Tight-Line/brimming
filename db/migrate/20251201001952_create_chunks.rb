# frozen_string_literal: true

class CreateChunks < ActiveRecord::Migration[8.1]
  def change
    create_table :chunks do |t|
      # Polymorphic association - chunks can belong to Question or Article
      t.references :chunkable, polymorphic: true, null: false

      # Ordering within the parent document
      t.integer :chunk_index, null: false, default: 0

      # The actual chunk content
      t.text :content, null: false

      # Token count for context window management
      t.integer :token_count

      # Vector embedding (dimension-less like questions.embedding)
      t.vector :embedding

      # Embedding metadata
      t.datetime :embedded_at
      t.references :embedding_provider, foreign_key: true

      # Source metadata (e.g., which answer or comment this chunk came from)
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    # Index for finding chunks by parent document
    add_index :chunks, [ :chunkable_type, :chunkable_id, :chunk_index ],
              name: "index_chunks_on_chunkable_and_index"

    # Index for finding chunks that need embedding
    add_index :chunks, :embedded_at, where: "embedded_at IS NULL",
              name: "index_chunks_on_unembedded"

    # Note: HNSW index for vector search will be created dynamically
    # by EmbeddingIndexService when an embedding provider is enabled.
    # Example:
    #   CREATE INDEX index_chunks_on_embedding
    #   ON chunks USING hnsw ((embedding::vector(1536)) vector_cosine_ops)
  end
end
