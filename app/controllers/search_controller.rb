# frozen_string_literal: true

class SearchController < ApplicationController
  # GET /search
  def index
    @query = params[:q]
    @space = Space.find_by(slug: params[:space]) if params[:space].present?
    @user = User.find_by(username: params[:user]) if params[:user].present?
    @tags = params[:tags] || []
    @sort = params[:sort]

    @results = search_service.new(
      q: @query,
      space_id: @space&.id,
      user_id: @user&.id,
      tags: @tags,
      sort: @sort,
      page: params[:page],
      per_page: params[:per_page]
    ).call

    respond_to do |format|
      format.html
      format.json { render json: search_results_json }
    end
  end

  # GET /search/suggestions
  def suggestions
    result = Search::SuggestionsService.new(
      params[:q],
      space_id: params[:space_id]
    ).call

    render json: result
  end

  private

  # HybridQueryService handles both semantic search (when available)
  # and keyword-only search (as fallback)
  def search_service
    Search::HybridQueryService
  end

  def search_results_json
    {
      query: @query,
      filters: {
        space: @space&.slug,
        user: @user&.username,
        tags: @tags
      },
      results: @results.hits.map { |hit| format_hit(hit) },
      pagination: {
        page: @results.page,
        per_page: @results.per_page,
        total: @results.total,
        total_pages: @results.total_pages
      }
    }
  end

  def format_hit(hit)
    source = hit.source
    question = source["question"]

    {
      id: question["id"],
      slug: question["slug"],
      title: question["title"],
      excerpt: truncate_body(question["body"]),
      vote_score: question["vote_score"],
      views_count: question["views_count"],
      has_correct_answer: question["has_correct_answer"],
      created_at: question["created_at"],
      author: source["author"],
      space: source["space"],
      tags: source["tags"],
      answer_count: source["answer_count"],
      comment_count: source["comment_count"],
      score: hit.score
    }
  end

  def truncate_body(body)
    # Body is always present per Question validation
    body.truncate(200)
  end
end
