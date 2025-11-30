# frozen_string_literal: true

module Search
  # Service for providing search suggestions (autocomplete)
  # Uses PostgreSQL pg_trgm for fast prefix/similarity matching
  class SuggestionsService
    MAX_SUGGESTIONS = 5

    def initialize(query, space_id: nil)
      @query = query.to_s.strip
      @space_id = space_id
    end

    def call
      return empty_result if @query.blank?

      questions = build_query.limit(MAX_SUGGESTIONS)

      {
        questions: questions.map do |q|
          {
            id: q.id,
            title: q.title,
            slug: q.slug,
            space_slug: q.space.slug
          }
        end
      }
    rescue => e
      Rails.logger.error("[Search::SuggestionsService] Suggestions failed: #{e.message}")
      empty_result
    end

    private

    def build_query
      scope = Question.not_deleted.includes(:space)

      scope = scope.where(space_id: @space_id) if @space_id.present?

      # Use ILIKE for case-insensitive prefix/contains matching
      # The pg_trgm GIN index accelerates this query
      scope
        .where("title ILIKE ?", "%#{sanitize_like(@query)}%")
        .order(Arel.sql("similarity(title, #{Question.connection.quote(@query)}) DESC"))
    end

    def sanitize_like(value)
      value.gsub(/[%_\\]/) { |m| "\\#{m}" }
    end

    def empty_result
      { questions: [] }
    end
  end
end
