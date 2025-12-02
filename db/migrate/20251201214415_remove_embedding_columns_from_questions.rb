class RemoveEmbeddingColumnsFromQuestions < ActiveRecord::Migration[8.1]
  def change
    # Remove the legacy embedding column and its vector index
    # Embeddings are now stored in the chunks table for RAG chunking
    remove_index :questions, name: :index_questions_on_embedding_hnsw, if_exists: true
    remove_column :questions, :embedding, :vector
    remove_column :questions, :embedding_provider_id, :bigint

    # Keep embedded_at as it's still used to track when chunking was last done
  end
end
