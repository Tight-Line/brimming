# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :require_login, only: [ :create, :edit, :update, :destroy, :hard_delete, :upvote, :remove_vote ]
  before_action :set_comment, only: [ :edit, :update, :destroy, :hard_delete, :upvote, :remove_vote ]
  before_action :set_commentable, only: [ :create ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy ]
  before_action :authorize_moderator!, only: [ :hard_delete ]

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

  def edit
  end

  def update
    if @comment.update(comment_params)
      @comment.record_edit!(current_user)
      redirect_to redirect_path_for_existing_comment, notice: "Comment updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.soft_delete!
    redirect_to redirect_path_for_existing_comment, notice: "Comment deleted.", status: :see_other
  end

  def hard_delete
    redirect_path = redirect_path_for_hard_delete
    @comment.destroy!
    redirect_to redirect_path, notice: "Comment permanently deleted.", status: :see_other
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
    question = @commentable.is_a?(Question) ? @commentable : @commentable.question
    question_path(question, anchor: "comment-#{@comment.id}")
  end

  def redirect_path_for_existing_comment
    commentable = @comment.commentable
    question = commentable.is_a?(Question) ? commentable : commentable.question
    question_path(question, anchor: "comment-#{@comment.id}")
  end

  def redirect_path_for_hard_delete
    commentable = @comment.commentable
    question = commentable.is_a?(Question) ? commentable : commentable.question
    # For hard delete, redirect to parent comment if it's a reply, or to the commentable
    if @comment.parent_comment
      question_path(question, anchor: "comment-#{@comment.parent_comment_id}")
    elsif commentable.is_a?(Answer)
      question_path(question, anchor: "answer-#{commentable.id}")
    else
      question_path(question)
    end
  end

  def authorize_owner!
    return if @comment.owned_by?(current_user)

    redirect_to redirect_path_for_existing_comment, alert: "You can only edit or delete your own comments."
  end

  def authorize_moderator!
    return if current_user.can_moderate?(@comment.space)

    redirect_to redirect_path_for_existing_comment, alert: "Only moderators can permanently delete content."
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
