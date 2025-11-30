# frozen_string_literal: true

module Search
  # Service for semantic search using pgvector embeddings.
  # Generates an embedding for the query and finds similar questions.
  class VectorQueryService
    DEFAULT_LIMIT = 20
    MAX_LIMIT = 100
    # Fallback threshold if no provider configured
    FALLBACK_SIMILARITY_THRESHOLD = 0.3

    Result = Struct.new(:hits, :total, :similarity_threshold, keyword_init: true)
    Hit = Struct.new(:id, :score, :question, keyword_init: true)

    def initialize(params = {})
      @query = params[:q].to_s.strip
      @space_id = params[:space_id]
      limit_param = params[:limit].to_i
      @limit = limit_param > 0 ? [ limit_param, MAX_LIMIT ].min : DEFAULT_LIMIT
      @offset = [ params[:offset].to_i, 0 ].max
      @similarity_threshold = params[:similarity_threshold]
    end

    def call
      return empty_result if @query.blank?
      return empty_result unless EmbeddingService.available?

      query_embedding = generate_query_embedding
      return empty_result if query_embedding.nil?

      questions = find_similar_questions(query_embedding)
      hits = questions.map { |q| build_hit(q) }

      # Filter out results below the similarity threshold
      threshold = effective_similarity_threshold
      hits = hits.select { |hit| hit.score >= threshold }

      Result.new(
        hits: hits,
        total: hits.size,
        similarity_threshold: threshold
      )
    rescue EmbeddingService::Adapters::Base::ApiError => e
      Rails.logger.error("[Search::VectorQueryService] Embedding API error: #{e.message}")
      empty_result
    rescue => e
      Rails.logger.error("[Search::VectorQueryService] Unexpected error: #{e.message}")
      empty_result
    end

    private

    def generate_query_embedding
      service = EmbeddingService.client
      service.embed_one(@query)
    rescue EmbeddingService::Client::NoProviderError
      Rails.logger.warn("[Search::VectorQueryService] No embedding provider configured")
      nil
    end

    def find_similar_questions(query_embedding)
      scope = Question.not_deleted.where.not(embedding: nil)
      scope = scope.where(space_id: @space_id) if @space_id.present?

      # Use pgvector's nearest_neighbors with cosine distance
      scope.nearest_neighbors(:embedding, query_embedding, distance: "cosine")
           .offset(@offset)
           .limit(@limit)
           .includes(:user, :space, :tags)
    end

    def build_hit(question)
      # neighbor_distance is the cosine distance (0 = identical, 2 = opposite)
      # Convert to similarity score (1 = identical, 0 = orthogonal, -1 = opposite)
      distance = question.neighbor_distance || 0
      similarity = 1.0 - distance

      Hit.new(
        id: question.id,
        score: similarity,
        question: question
      )
    end

    def effective_similarity_threshold
      return @similarity_threshold if @similarity_threshold.present?

      provider = EmbeddingProvider.enabled.first
      provider&.similarity_threshold || FALLBACK_SIMILARITY_THRESHOLD
    end

    def empty_result
      Result.new(hits: [], total: 0, similarity_threshold: effective_similarity_threshold)
    end
  end
end
