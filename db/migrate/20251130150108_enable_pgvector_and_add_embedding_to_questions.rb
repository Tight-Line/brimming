# frozen_string_literal: true

class EnablePgvectorAndAddEmbeddingToQuestions < ActiveRecord::Migration[8.1]
  def up
    # Enable the pgvector extension in public schema for portability
    # (works whether we own the DB or use a managed/shared DB)
    execute "CREATE EXTENSION IF NOT EXISTS vector"

    # Add embedding column to questions table
    # Using vector type without dimension constraint for flexibility
    # (different embedding providers use different dimensions)
    add_column :questions, :embedding, :vector

    # Add timestamp for when the embedding was last generated
    add_column :questions, :embedded_at, :datetime

    # Note: HNSW index requires vectors with fixed dimensions.
    # The index will be created dynamically by EmbeddingIndexService
    # when an embedding provider is enabled with known dimensions.
    # Example index creation:
    #   CREATE INDEX CONCURRENTLY index_questions_on_embedding
    #   ON brimming.questions
    #   USING hnsw ((embedding::vector(1536)) vector_cosine_ops)
    #   WITH (m = 16, ef_construction = 64);
  end

  def down
    # Drop the HNSW index if it exists (index lives in brimming schema with the table)
    execute "DROP INDEX IF EXISTS brimming.index_questions_on_embedding"

    remove_column :questions, :embedded_at
    remove_column :questions, :embedding

    # Note: We don't drop the extension as other tables might use it
  end
end
