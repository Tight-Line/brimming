# frozen_string_literal: true

# Regenerates embeddings for all questions when the embedding provider changes.
#
# This job is triggered when a new embedding provider is activated. It:
# 1. Invalidates all embeddings from the old provider
# 2. Queues individual embedding jobs for each question
#
# Usage:
#   RegenerateAllEmbeddingsJob.perform_later(new_provider_id)
#
class RegenerateAllEmbeddingsJob < ApplicationJob
  queue_as :embeddings

  def perform(new_provider_id)
    provider = EmbeddingProvider.find_by(id: new_provider_id)
    return unless provider&.enabled?

    # Invalidate all embeddings from other providers
    invalidated_count = Question.where.not(embedding_provider_id: [ nil, provider.id ])
                                .update_all(embedding: nil, embedding_provider_id: nil, embedded_at: nil)

    Rails.logger.info("[RegenerateAllEmbeddingsJob] Invalidated #{invalidated_count} embeddings from previous providers")

    # Queue embedding jobs for all questions that need embeddings
    Question.not_deleted.find_each do |question|
      # Skip if already embedded by the current provider
      next if question.embedding_provider_id == provider.id && question.embedded_at.present?

      GenerateQuestionEmbeddingJob.perform_later(question)
    end

    questions_to_embed = Question.not_deleted
                                 .where(embedding_provider_id: [ nil ])
                                 .or(Question.not_deleted.where.not(embedding_provider_id: provider.id))
                                 .count

    Rails.logger.info("[RegenerateAllEmbeddingsJob] Queued #{questions_to_embed} questions for embedding with #{provider.name}")
  end
end
