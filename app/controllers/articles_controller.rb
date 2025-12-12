# frozen_string_literal: true

class ArticlesController < ApplicationController
  before_action :require_login, only: [ :new, :create, :edit, :update, :destroy, :hard_delete, :upvote, :remove_vote, :refresh_from_source ]
  before_action :set_article, only: [ :show, :edit, :update, :destroy, :hard_delete, :upvote, :remove_vote, :refresh_from_source ]

  def index
    @articles = policy_scope(Article).recent.includes(:user, :spaces)
    @articles = @articles.joins(:spaces).where(spaces: { slug: params[:space] }).distinct if params[:space].present?
  end

  def show
    authorize @article
    if @article.deleted?
      redirect_to articles_path, alert: "This article has been deleted."
      return
    end
    @article.increment_views!
    @article_comments = @article.comments.top_level.includes(:user, replies: [ :user, { replies: :user } ]).recent
  end

  def new
    @article = Article.new(content_type: "markdown")
    authorize @article
    @spaces = current_user.publishable_spaces.alphabetical
  end

  def create
    @article = current_user.articles.build(article_params)
    authorize @article

    # Handle webpage mode - fetch content from URL
    if params[:article][:input_mode] == "webpage"
      result = fetch_webpage_content
      unless result
        @spaces = current_user.publishable_spaces.alphabetical
        render :new, status: :unprocessable_entity
        return
      end
    end

    # Filter space_ids to only those the user can publish to
    if params[:article][:space_ids].present?
      allowed_space_ids = current_user.publishable_spaces.pluck(:id).map(&:to_s)
      @article.space_ids = params[:article][:space_ids] & allowed_space_ids
    end

    if @article.save
      redirect_to @article, notice: "Article created successfully."
    else
      @spaces = current_user.publishable_spaces.alphabetical
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @article
    @spaces = current_user.publishable_spaces.alphabetical
  end

  def update
    authorize @article

    # Filter space_ids to only those the user can publish to
    if params[:article][:space_ids].present?
      allowed_space_ids = current_user.publishable_spaces.pluck(:id).map(&:to_s)
      filtered_space_ids = params[:article][:space_ids] & allowed_space_ids
      # Preserve spaces the user can't modify
      other_space_ids = @article.space_ids - current_user.publishable_spaces.pluck(:id)
      @article.space_ids = filtered_space_ids.map(&:to_i) + other_space_ids
    end

    if @article.update(article_params.except(:space_ids))
      @article.mark_edited!(current_user)
      redirect_to @article, notice: "Article updated successfully.", status: :see_other
    else
      @spaces = current_user.publishable_spaces.alphabetical
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @article
    @article.soft_delete!
    redirect_to articles_path, notice: "Article deleted.", status: :see_other
  end

  def hard_delete
    authorize @article
    @article.destroy!
    redirect_to articles_path, notice: "Article permanently deleted.", status: :see_other
  end

  def upvote
    authorize @article, :vote?
    @article.upvote_by(current_user)
    respond_to_vote
  end

  def remove_vote
    authorize @article, :vote?
    @article.remove_vote_by(current_user)
    respond_to_vote
  end

  def refresh_from_source
    authorize @article, :update?

    unless @article.webpage_content? && @article.source_url.present?
      redirect_to @article, alert: "This article does not have a web page source."
      return
    end

    # Use selected provider, article's existing provider, or default to enabled provider
    provider = if params[:reader_provider_id].present?
                 ReaderProvider.find_by(id: params[:reader_provider_id])
    elsif @article.reader_provider_id.present?
                 @article.reader_provider
    else
                 ReaderProvider.enabled_provider
    end

    result = WebPageFetchService.new(@article.source_url, provider: provider).fetch
    if result.success?
      @article.update!(body: result.content, reader_provider: provider)
      @article.mark_edited!(current_user)
      redirect_to @article, notice: "Content refreshed from source."
    else
      redirect_to @article, alert: "Failed to refresh content: #{result.error}"
    end
  end

  private

  def set_article
    @article = Article.find_by!(slug: params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :body, :input_mode, :original_file, :source_url, :reader_provider_id, space_ids: [])
  end

  def fetch_webpage_content
    unless @article.source_url.present?
      @article.errors.add(:source_url, "is required for web page import")
      return false
    end

    # Use selected provider or default to enabled provider
    provider = if @article.reader_provider_id.present?
                 ReaderProvider.find_by(id: @article.reader_provider_id)
    else
                 ReaderProvider.enabled_provider
    end

    result = WebPageFetchService.new(@article.source_url, provider: provider).fetch
    if result.success?
      @article.body = result.content
      @article.content_type = "webpage"
      @article.reader_provider = provider
      true
    else
      @article.errors.add(:source_url, result.error)
      false
    end
  end

  def respond_to_vote
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "article-#{@article.id}-votes",
          partial: "votes/article_vote_button",
          locals: { article: @article }
        )
      end
      format.html { redirect_to @article }
    end
  end
end
