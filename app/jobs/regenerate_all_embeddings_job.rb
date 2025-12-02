# frozen_string_literal: true

# Regenerates embeddings for all questions and articles when the embedding provider changes.
#
# This job is triggered when a new embedding provider is activated. It:
# 1. Invalidates all embeddings from the old provider
# 2. Queues individual embedding jobs for each question and article
#
# Usage:
#   RegenerateAllEmbeddingsJob.perform_later(new_provider_id)
#
class RegenerateAllEmbeddingsJob < ApplicationJob
  queue_as :embeddings

  def perform(new_provider_id)
    provider = EmbeddingProvider.find_by(id: new_provider_id)
    return unless provider&.enabled?

    # Delete all chunks from other providers
    deleted_chunks = Chunk.where.not(embedding_provider_id: [ nil, provider.id ]).delete_all

    # Reset embedded_at for questions that had chunks deleted
    Question.where.not(embedded_at: nil).update_all(embedded_at: nil)

    Rails.logger.info("[RegenerateAllEmbeddingsJob] Deleted #{deleted_chunks} chunks from previous providers")

    # Queue embedding jobs for all questions that need embeddings
    questions_queued = 0
    Question.not_deleted.find_each do |question|
      # Skip if already has chunks from the current provider
      next if question.chunks.where(embedding_provider_id: provider.id).exists?

      GenerateQuestionEmbeddingJob.perform_later(question)
      questions_queued += 1
    end

    Rails.logger.info("[RegenerateAllEmbeddingsJob] Queued #{questions_queued} questions for embedding with #{provider.name}")

    # Queue embedding jobs for all articles that need embeddings
    articles_queued = 0
    Article.active.find_each do |article|
      # Skip if already has chunks from the current provider
      next if article.chunks.where(embedding_provider_id: provider.id).exists?

      GenerateArticleEmbeddingJob.perform_later(article)
      articles_queued += 1
    end

    Rails.logger.info("[RegenerateAllEmbeddingsJob] Queued #{articles_queued} articles for embedding with #{provider.name}")
  end
end
