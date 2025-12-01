# frozen_string_literal: true

# Generates vector embeddings for articles using the configured embedding provider.
#
# This job uses ArticleEmbeddingService to:
# 1. Extract text content from the article
# 2. Chunk the content for RAG
# 3. Generate embeddings for each chunk
#
# Usage:
#   GenerateArticleEmbeddingJob.perform_later(article)
#   GenerateArticleEmbeddingJob.perform_later(article, force: true)
#
class GenerateArticleEmbeddingJob < ApplicationJob
  queue_as :embeddings

  # Retry with exponential backoff for API errors
  retry_on EmbeddingService::Adapters::Base::RateLimitError, wait: :polynomially_longer, attempts: 5
  retry_on EmbeddingService::Adapters::Base::ApiError, wait: 5.seconds, attempts: 3

  # Don't retry if no provider is configured
  discard_on EmbeddingService::Client::NoProviderError

  def perform(article, force: false)
    # Skip if no embedding provider is configured
    provider = EmbeddingService.current_provider
    return unless provider

    # Skip if already embedded by the current provider and not forcing regeneration
    unless force
      has_chunks = article.chunks.where(embedding_provider_id: provider.id).exists?
      return if has_chunks
    end

    # Skip deleted articles
    return if article.deleted_at.present?

    # Use ArticleEmbeddingService to create chunks and embeddings
    result = ArticleEmbeddingService.embed(article, provider: provider)

    if result[:success]
      Rails.logger.info("[GenerateArticleEmbeddingJob] Generated #{result[:chunks]} chunks for Article##{article.id} using #{provider.name}")
    else
      Rails.logger.error("[GenerateArticleEmbeddingJob] Failed to embed Article##{article.id}: #{result[:error]}")
    end
  rescue EmbeddingService::Adapters::Base::ConfigurationError => e
    Rails.logger.error("[GenerateArticleEmbeddingJob] Configuration error: #{e.message}")
    # Don't retry configuration errors
  end
end
