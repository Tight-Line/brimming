# frozen_string_literal: true

# Generates vector embeddings for questions using the configured embedding provider.
#
# This job uses QuestionEmbeddingService to:
# 1. Prepare text content (question title + body + best answer)
# 2. Chunk the content for RAG
# 3. Generate embeddings for each chunk
#
# Usage:
#   GenerateQuestionEmbeddingJob.perform_later(question)
#   GenerateQuestionEmbeddingJob.perform_later(question, force: true)
#
class GenerateQuestionEmbeddingJob < ApplicationJob
  queue_as :embeddings

  def perform(question, force: false)
    # Skip if no embedding provider is configured
    provider = EmbeddingService.current_provider
    return unless provider

    # Skip if already has chunks from the current provider and not forcing regeneration
    unless force
      has_chunks = question.chunks.where(embedding_provider_id: provider.id).exists?
      return if has_chunks
    end

    # Skip deleted questions
    return if question.deleted_at.present?

    # Use QuestionEmbeddingService to create chunks and embeddings
    result = QuestionEmbeddingService.embed(question, provider: provider)

    if result[:success]
      Rails.logger.info("[GenerateQuestionEmbeddingJob] Generated #{result[:chunks]} chunks for Question##{question.id} using #{provider.name}")
    else
      Rails.logger.error("[GenerateQuestionEmbeddingJob] Failed to embed Question##{question.id}: #{result[:error]}")
    end
  end
end
