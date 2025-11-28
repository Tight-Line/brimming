# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :require_login, only: [ :upvote, :remove_vote ]
  before_action :set_comment

  def upvote
    @comment.upvote_by(current_user)
    respond_to_vote
  end

  def remove_vote
    @comment.remove_vote_by(current_user)
    respond_to_vote
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def respond_to_vote
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "comment-#{@comment.id}-votes",
          partial: "votes/comment_vote_button",
          locals: { comment: @comment }
        )
      end
      format.html { redirect_back fallback_location: root_path }
    end
  end
end
