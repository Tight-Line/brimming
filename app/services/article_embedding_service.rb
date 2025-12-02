# frozen_string_literal: true

# Service for creating and managing article embeddings using chunks.
#
# This service:
# 1. Extracts text content from the article
# 2. Chunks the content using ChunkingService
# 3. Creates/updates Chunk records for the article
# 4. Generates embeddings for each chunk
#
# Usage:
#   ArticleEmbeddingService.embed(article)
#   ArticleEmbeddingService.embed(article, provider: specific_provider)
#
class ArticleEmbeddingService
  class Error < StandardError; end

  def self.embed(article, provider: nil)
    new(article, provider: provider).embed
  end

  def initialize(article, provider: nil)
    @article = article
    @provider = provider || EmbeddingProvider.enabled.first
  end

  def embed
    return { success: false, error: "No embedding provider available" } unless @provider

    # Extract content from the article
    content = ContentExtractionService.extract(@article)
    return { success: true, chunks: 0, message: "No content to embed" } if content.blank?

    # Chunk the content
    chunking_service = ChunkingService.new(@provider)
    chunk_data = chunking_service.chunk_text(content)

    # Use a transaction to ensure all-or-nothing chunk creation
    chunks_created = 0
    ActiveRecord::Base.transaction do
      # Remove old chunks for this article
      @article.chunks.destroy_all

      # Create new chunks and generate embeddings
      embedding_client = EmbeddingService::Client.new(@provider)

      chunk_data.each_with_index do |data, index|
        chunk = @article.chunks.create!(
          content: data[:content],
          chunk_index: index,
          token_count: data[:token_count],
          metadata: { position: data[:position] },
          embedding_provider: @provider
        )

        # Generate embedding
        embedding = embedding_client.embed_one(data[:content])
        chunk.set_embedding!(embedding, provider: @provider)
        chunks_created += 1
      end

      # Update embedded_at timestamp
      @article.update!(embedded_at: Time.current)
    end

    { success: true, chunks: chunks_created }
  rescue EmbeddingService::Client::Error, EmbeddingService::Adapters::Base::Error => e
    { success: false, error: e.message }
  end
end
