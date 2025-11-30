# frozen_string_literal: true

module Search
  # Hybrid search service combining PostgreSQL keyword search with
  # semantic search (pgvector).
  #
  # Strategy: Vector-first with keyword fallback
  # 1. If embeddings available, use vector search (semantic matches)
  # 2. If vector returns results above threshold, use those
  # 3. Otherwise fall back to PostgreSQL full-text search
  #
  # This prioritizes semantic relevance when embeddings are good,
  # while ensuring users always get results via keyword fallback.
  class HybridQueryService
    DEFAULT_PER_PAGE = 20
    MAX_PER_PAGE = 100

    Result = Struct.new(:hits, :total, :page, :per_page, :total_pages, :search_mode, :similarity_threshold, keyword_init: true)
    Hit = Struct.new(:id, :score, :source, :keyword_rank, :vector_rank, :vector_score, keyword_init: true)

    def initialize(params = {})
      @query = params[:q].to_s.strip
      @space_id = params[:space_id]
      @user_id = params[:user_id]
      @tags = Array(params[:tags]).reject(&:blank?)
      @sort = params[:sort] || "relevance"
      @page = [ [ params[:page].to_i, 1 ].max, 1 ].max
      @per_page = [ [ params[:per_page].to_i, DEFAULT_PER_PAGE ].max, MAX_PER_PAGE ].min
    end

    def call
      return empty_result(:none) if @query.blank? && @tags.empty? && @space_id.blank? && @user_id.blank?

      # For non-relevance sorts, just use keyword search
      return keyword_only_search if @sort != "relevance" || @query.blank?

      # Try vector search first if embeddings are available
      if EmbeddingService.available?
        vector_results = run_vector_search
        if vector_results.any?
          return format_vector_results(vector_results, :vector)
        end
      end

      # Fall back to keyword search
      keyword_only_search
    rescue => e
      Rails.logger.error("[Search::HybridQueryService] Search failed: #{e.message}")
      empty_result(:error)
    end

    private

    def keyword_only_search
      questions = build_keyword_query
      total = questions.count
      page_questions = questions.offset((@page - 1) * @per_page).limit(@per_page)

      format_keyword_results(page_questions, total, :keyword)
    rescue => e
      Rails.logger.error("[Search::HybridQueryService] Keyword search failed: #{e.message}")
      empty_result(:error)
    end

    def run_vector_search
      # EmbeddingService.available? is already checked before calling this method
      vector_service = VectorQueryService.new(
        q: @query,
        space_id: @space_id,
        limit: @per_page * 3
      )

      result = vector_service.call
      result.hits
    rescue => e
      Rails.logger.error("[Search::HybridQueryService] Vector search failed: #{e.message}")
      []
    end

    def build_keyword_query
      scope = Question.not_deleted.includes(:user, :space, :tags, :answers)

      # Apply filters
      scope = scope.where(space_id: @space_id) if @space_id.present?
      scope = scope.where(user_id: @user_id) if @user_id.present?
      scope = apply_tag_filter(scope) if @tags.present?

      # Apply full-text search or sorting
      if @query.present? && @sort == "relevance"
        scope = apply_fulltext_search(scope)
      else
        scope = apply_sort(scope)
      end

      scope
    end

    def apply_fulltext_search(scope)
      # Convert query to tsquery format
      # plainto_tsquery handles natural language input
      scope
        .where("search_vector @@ plainto_tsquery('english', ?)", @query)
        .order(Arel.sql("ts_rank(search_vector, plainto_tsquery('english', #{Question.connection.quote(@query)})) DESC"))
    end

    def apply_tag_filter(scope)
      # Questions that have any of the specified tags
      scope.joins(:tags).where(tags: { name: @tags }).distinct
    end

    def apply_sort(scope)
      case @sort
      when "newest"
        scope.order(created_at: :desc)
      when "oldest"
        scope.order(created_at: :asc)
      when "votes"
        scope.order(vote_score: :desc, created_at: :desc)
      when "activity"
        scope.order(updated_at: :desc)
      else # relevance with no query
        scope.order(created_at: :desc)
      end
    end

    def format_vector_results(vector_hits, mode)
      total = vector_hits.size
      start_idx = (@page - 1) * @per_page
      page_hits = vector_hits[start_idx, @per_page] || []

      Result.new(
        hits: page_hits.map.with_index do |hit, idx|
          Hit.new(
            id: hit.id,
            score: hit.score,
            source: build_source_from_question(hit.question),
            keyword_rank: nil,
            vector_rank: start_idx + idx + 1,
            vector_score: hit.score
          )
        end,
        total: total,
        page: @page,
        per_page: @per_page,
        total_pages: (total.to_f / @per_page).ceil,
        search_mode: mode,
        similarity_threshold: vector_similarity_threshold
      )
    end

    def build_source_from_question(question)
      # Build a minimal source structure from a Question record
      # This is used when a result only appears in vector search
      {
        "question" => {
          "id" => question.id,
          "title" => question.title,
          "body" => question.body,
          "slug" => question.slug,
          "vote_score" => question.vote_score,
          "views_count" => question.views_count,
          "has_correct_answer" => question.has_correct_answer?,
          "created_at" => question.created_at.iso8601
        },
        "author" => {
          "id" => question.user.id,
          "username" => question.user.username,
          "display_name" => question.user.display_name
        },
        "space" => {
          "id" => question.space.id,
          "name" => question.space.name,
          "slug" => question.space.slug
        },
        "tags" => question.tag_names,
        "answer_count" => question.answers_count,
        "comment_count" => question.comments.count
      }
    end

    def format_keyword_results(questions, total, mode)
      Result.new(
        hits: questions.map { |q| build_keyword_hit(q) },
        total: total,
        page: @page,
        per_page: @per_page,
        total_pages: (total.to_f / @per_page).ceil,
        search_mode: mode,
        similarity_threshold: nil
      )
    end

    def build_keyword_hit(question)
      Hit.new(
        id: question.id.to_s,
        score: nil,
        source: build_source_from_question(question),
        keyword_rank: nil,
        vector_rank: nil,
        vector_score: nil
      )
    end

    def empty_result(mode)
      Result.new(
        hits: [],
        total: 0,
        page: @page,
        per_page: @per_page,
        total_pages: 0,
        search_mode: mode,
        similarity_threshold: nil
      )
    end

    def vector_similarity_threshold
      # This is only called from format_vector_results, which requires an enabled provider
      EmbeddingProvider.enabled.first.similarity_threshold
    end
  end
end
