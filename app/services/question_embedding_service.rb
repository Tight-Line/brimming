# frozen_string_literal: true

# Service for creating and managing question embeddings using chunks.
#
# This service:
# 1. Prepares text content from the question (title, body, best answer)
# 2. Chunks the content using ChunkingService
# 3. Creates/updates Chunk records for the question
# 4. Generates embeddings for each chunk
#
# Usage:
#   QuestionEmbeddingService.embed(question)
#   QuestionEmbeddingService.embed(question, provider: specific_provider)
#
class QuestionEmbeddingService
  class Error < StandardError; end

  def self.embed(question, provider: nil)
    new(question, provider: provider).embed
  end

  def initialize(question, provider: nil)
    @question = question
    @provider = provider || EmbeddingProvider.enabled.first
  end

  def embed
    return { success: false, error: "No embedding provider available" } unless @provider

    # Prepare content from the question
    content = prepare_content
    return { success: true, chunks: 0, message: "No content to embed" } if content.blank?

    # Chunk the content
    chunking_service = ChunkingService.new(@provider)
    chunk_data = chunking_service.chunk_text(content)

    # Use a transaction to ensure all-or-nothing chunk creation
    ActiveRecord::Base.transaction do
      # Remove old chunks for this question
      @question.chunks.destroy_all

      # Create new chunks and generate embeddings
      embedding_client = EmbeddingService::Client.new(@provider)

      chunk_data.each_with_index do |data, index|
        chunk = @question.chunks.create!(
          content: data[:content],
          chunk_index: index,
          token_count: data[:token_count],
          metadata: { position: data[:position] },
          embedding_provider: @provider
        )

        # Generate embedding
        embedding = embedding_client.embed_one(data[:content])
        chunk.set_embedding!(embedding, provider: @provider)
      end

      # Update embedded_at timestamp to track when this question was last embedded
      @question.update!(embedded_at: Time.current)
    end

    { success: true, chunks: chunk_data.length }
  rescue EmbeddingService::Client::Error, EmbeddingService::Adapters::Base::Error => e
    { success: false, error: e.message }
  end

  private

  def prepare_content
    EmbeddingService.prepare_question_text(@question)
  end
end
