# frozen_string_literal: true

# Generates vector embeddings for questions using the configured embedding provider.
#
# This job prepares text content (question title + body + best answer) and
# generates a vector embedding that enables semantic search.
#
# Usage:
#   GenerateQuestionEmbeddingJob.perform_later(question)
#   GenerateQuestionEmbeddingJob.perform_later(question, force: true)
#
class GenerateQuestionEmbeddingJob < ApplicationJob
  queue_as :embeddings

  # Retry with exponential backoff for API errors
  retry_on EmbeddingService::Adapters::Base::RateLimitError, wait: :polynomially_longer, attempts: 5
  retry_on EmbeddingService::Adapters::Base::ApiError, wait: 5.seconds, attempts: 3

  # Don't retry if no provider is configured
  discard_on EmbeddingService::Client::NoProviderError

  def perform(question, force: false)
    # Skip if no embedding provider is configured
    provider = EmbeddingService.current_provider
    return unless provider

    # Skip if already embedded by the current provider and not forcing regeneration
    return if question.embedded_at.present? &&
              question.embedding_provider_id == provider.id &&
              !force

    # Skip deleted questions
    return if question.deleted_at.present?

    # Prepare text for embedding
    text = EmbeddingService.prepare_question_text(question)

    # Generate embedding
    service = EmbeddingService.client(provider)
    embedding = service.embed_one(text)

    # Save embedding to the question with provider reference
    question.update_columns(
      embedding: embedding,
      embedding_provider_id: provider.id,
      embedded_at: Time.current
    )

    Rails.logger.info("[GenerateQuestionEmbeddingJob] Generated embedding for Question##{question.id} using #{provider.name}")
  rescue EmbeddingService::Adapters::Base::ConfigurationError => e
    Rails.logger.error("[GenerateQuestionEmbeddingJob] Configuration error: #{e.message}")
    # Don't retry configuration errors
  end
end
