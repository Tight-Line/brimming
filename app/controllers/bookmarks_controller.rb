# frozen_string_literal: true

class BookmarksController < ApplicationController
  before_action :require_login
  before_action :set_bookmark, only: [ :update, :destroy ]

  def index
    authorize Bookmark
    @bookmarks = policy_scope(Bookmark).recent.includes(:bookmarkable)
    @filter = params[:type]

    if @filter.present? && Bookmark::BOOKMARKABLE_TYPES.include?(@filter)
      @bookmarks = @bookmarks.where(bookmarkable_type: @filter)
    end
  end

  def create
    bookmarkable = find_bookmarkable
    @bookmark = current_user.bookmarks.build(
      bookmarkable: bookmarkable,
      notes: bookmark_params[:notes]
    )
    authorize @bookmark

    if @bookmark.save
      respond_to do |format|
        format.turbo_stream { render_bookmark_button }
        format.html { redirect_back fallback_location: root_path, notice: "Bookmarked!" }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_back fallback_location: root_path, alert: "Could not bookmark." }
      end
    end
  end

  def update
    authorize @bookmark
    if @bookmark.update(bookmark_params)
      respond_to do |format|
        format.turbo_stream { render_bookmark_button }
        format.html { redirect_to bookmarks_path, notice: "Bookmark updated." }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_to bookmarks_path, alert: "Could not update bookmark." }
      end
    end
  end

  def destroy
    authorize @bookmark
    bookmarkable = @bookmark.bookmarkable
    bookmark_id = @bookmark.id
    @bookmark.destroy!

    respond_to do |format|
      format.turbo_stream do
        if params[:from_index]
          # Remove the bookmark item from the list on the bookmarks index page
          render turbo_stream: turbo_stream.remove("bookmark_#{bookmark_id}")
        else
          # Update the button on content pages
          render_bookmark_button(bookmarkable: bookmarkable, bookmark: nil)
        end
      end
      format.html { redirect_back fallback_location: bookmarks_path, notice: "Bookmark removed." }
    end
  end

  private

  def set_bookmark
    @bookmark = Bookmark.find(params[:id])
  end

  def bookmark_params
    params.require(:bookmark).permit(:notes, :bookmarkable_type, :bookmarkable_id)
  end

  def find_bookmarkable
    type = bookmark_params[:bookmarkable_type]
    id = bookmark_params[:bookmarkable_id]

    unless Bookmark::BOOKMARKABLE_TYPES.include?(type)
      raise ActiveRecord::RecordNotFound, "Invalid bookmarkable type"
    end

    type.constantize.find(id)
  end

  def render_bookmark_button(bookmarkable: nil, bookmark: :default)
    bookmarkable ||= @bookmark.bookmarkable
    bookmark = bookmark == :default ? @bookmark : bookmark

    render turbo_stream: turbo_stream.replace(
      "bookmark-#{bookmarkable.class.name.downcase}-#{bookmarkable.id}",
      partial: "bookmarks/bookmark_button",
      locals: { bookmarkable: bookmarkable, bookmark: bookmark }
    )
  end
end
