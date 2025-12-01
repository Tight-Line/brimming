# frozen_string_literal: true

module Search
  # Service for semantic search using chunk embeddings.
  # Searches across all chunkable types (Questions, Articles) and
  # returns results grouped by their parent documents.
  class ChunkVectorQueryService
    DEFAULT_LIMIT = 20
    MAX_LIMIT = 100
    # Fallback threshold if no provider configured
    FALLBACK_SIMILARITY_THRESHOLD = 0.3

    Result = Struct.new(:hits, :total, :similarity_threshold, keyword_init: true)
    Hit = Struct.new(:id, :score, :type, :chunkable, :best_chunk, keyword_init: true)

    def initialize(params = {})
      @query = params[:q].to_s.strip
      @space_id = params[:space_id]
      @types = Array(params[:types]).presence || %w[Question Article]
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

      chunks = find_similar_chunks(query_embedding)
      hits = group_chunks_by_chunkable(chunks)

      # Filter out results below the similarity threshold
      threshold = effective_similarity_threshold
      hits = hits.select { |hit| hit.score >= threshold }

      # Apply offset and limit after grouping
      hits = hits.drop(@offset).take(@limit)

      Result.new(
        hits: hits,
        total: hits.size,
        similarity_threshold: threshold
      )
    rescue EmbeddingService::Adapters::Base::ApiError => e
      Rails.logger.error("[Search::ChunkVectorQueryService] Embedding API error: #{e.message}")
      empty_result
    rescue => e
      Rails.logger.error("[Search::ChunkVectorQueryService] Unexpected error: #{e.message}")
      empty_result
    end

    private

    def generate_query_embedding
      service = EmbeddingService.client
      service.embed_one(@query)
    rescue EmbeddingService::Client::NoProviderError
      Rails.logger.warn("[Search::ChunkVectorQueryService] No embedding provider configured")
      nil
    end

    def find_similar_chunks(query_embedding)
      # Filter by chunkable type (defaults to Question and Article)
      scope = Chunk.embedded.where(chunkable_type: @types)

      # Use pgvector's nearest_neighbors with cosine distance
      # We fetch more chunks than needed since we'll group by chunkable
      fetch_limit = (@limit + @offset) * 3
      scope.nearest_neighbors(:embedding, query_embedding, distance: "cosine").limit(fetch_limit).includes(:chunkable)
    end

    def group_chunks_by_chunkable(chunks)
      # Group chunks by their parent document, keeping best score
      grouped = {}

      chunks.each do |chunk|
        next unless chunk.chunkable.present?
        next if filtered_out?(chunk.chunkable)

        key = "#{chunk.chunkable_type}-#{chunk.chunkable_id}"
        distance = chunk.neighbor_distance || 0
        similarity = 1.0 - distance

        if !grouped[key] || similarity > grouped[key][:score]
          grouped[key] = {
            score: similarity,
            chunkable: chunk.chunkable,
            best_chunk: chunk
          }
        end
      end

      # Sort by score descending and build hits
      grouped.values
             .sort_by { |g| -g[:score] }
             .map { |g| build_hit(g) }
    end

    def filtered_out?(chunkable)
      # Filter by space if applicable
      return false unless @space_id.present?

      # Only filter Question and Article types by space
      # Other types (if any) pass through without filtering
      return chunkable.space_id != @space_id.to_i if chunkable.is_a?(Question)
      return !chunkable.spaces.exists?(id: @space_id) if chunkable.is_a?(Article)

      false
    end

    def build_hit(data)
      Hit.new(
        id: data[:chunkable].id,
        score: data[:score],
        type: data[:chunkable].class.name,
        chunkable: data[:chunkable],
        best_chunk: data[:best_chunk]
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
