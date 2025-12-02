# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :require_login, only: [ :create, :edit, :update, :destroy, :hard_delete, :upvote, :remove_vote ]
  before_action :set_comment, only: [ :edit, :update, :destroy, :hard_delete, :upvote, :remove_vote ]
  before_action :set_commentable, only: [ :create ]

  def create
    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user

    # Handle replies
    if params[:parent_comment_id].present?
      @comment.parent_comment = Comment.find(params[:parent_comment_id])
    end

    authorize @comment

    if @comment.save
      # TODO: i18n
      redirect_to redirect_path_for_comment, notice: "Comment posted.", status: :see_other
    else
      redirect_to redirect_path_for_comment, alert: @comment.errors.full_messages.join(", "), status: :see_other
    end
  end

  def edit
    authorize @comment
  end

  def update
    authorize @comment
    if @comment.update(comment_params)
      @comment.record_edit!(current_user)
      # TODO: i18n
      redirect_to redirect_path_for_existing_comment, notice: "Comment updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @comment
    @comment.soft_delete!
    # TODO: i18n
    redirect_to redirect_path_for_existing_comment, notice: "Comment deleted.", status: :see_other
  end

  def hard_delete
    authorize @comment
    redirect_path = redirect_path_for_hard_delete
    @comment.destroy!
    # TODO: i18n
    redirect_to redirect_path, notice: "Comment permanently deleted.", status: :see_other
  end

  def upvote
    authorize @comment, :vote?
    @comment.upvote_by(current_user)
    respond_to_vote
  end

  def remove_vote
    authorize @comment, :vote?
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
    elsif params[:article_id].present?
      @commentable = Article.find_by!(slug: params[:article_id])
    elsif params[:comment_id].present?
      # For replies to comments
      parent = Comment.find(params[:comment_id])
      @commentable = parent.commentable
      params[:parent_comment_id] = parent.id
    else
      @commentable = Question.find_by!(slug: params[:question_id] || params[:id])
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def redirect_path_for_comment
    redirect_path_for_commentable(@commentable, @comment)
  end

  def redirect_path_for_existing_comment
    redirect_path_for_commentable(@comment.commentable, @comment)
  end

  def redirect_path_for_hard_delete
    commentable = @comment.commentable
    if commentable.is_a?(Article)
      return article_path(commentable)
    end

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

  def redirect_path_for_commentable(commentable, comment)
    case commentable
    when Article
      article_path(commentable, anchor: "comment-#{comment.id}")
    when Question
      question_path(commentable, anchor: "comment-#{comment.id}")
    when Answer
      question_path(commentable.question, anchor: "comment-#{comment.id}")
    else
      raise "Unknown commentable type: #{commentable.class.name}"
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
