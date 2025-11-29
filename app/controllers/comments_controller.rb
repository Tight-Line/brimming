# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :require_login, only: [ :create, :upvote, :remove_vote ]
  before_action :set_comment, only: [ :upvote, :remove_vote ]
  before_action :set_commentable, only: [ :create ]

  def create
    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user

    # Handle replies
    if params[:parent_comment_id].present?
      @comment.parent_comment = Comment.find(params[:parent_comment_id])
    end

    if @comment.save
      redirect_to redirect_path_for_comment, notice: "Comment posted.", status: :see_other
    else
      redirect_to redirect_path_for_comment, alert: @comment.errors.full_messages.join(", "), status: :see_other
    end
  end

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

  def set_commentable
    if params[:answer_id].present?
      @commentable = Answer.find(params[:answer_id])
    elsif params[:comment_id].present?
      # For replies to comments
      parent = Comment.find(params[:comment_id])
      @commentable = parent.commentable
      params[:parent_comment_id] = parent.id
    else
      @commentable = Question.find(params[:question_id] || params[:id])
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def redirect_path_for_comment
    case @commentable
    when Question
      question_path(@commentable, anchor: "comment-#{@comment.id}")
    when Answer
      question_path(@commentable.question, anchor: "comment-#{@comment.id}")
    else
      root_path
    end
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
