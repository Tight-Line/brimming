# frozen_string_literal: true

class AnswersController < ApplicationController
  before_action :require_login, only: [ :create, :edit, :update, :destroy, :hard_delete, :upvote, :downvote, :remove_vote ]
  before_action :set_question, only: [ :create ]
  before_action :set_answer, only: [ :edit, :update, :destroy, :hard_delete, :upvote, :downvote, :remove_vote ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy ]
  before_action :authorize_moderator!, only: [ :hard_delete ]

  def create
    @answer = @question.answers.build(answer_params)
    @answer.user = current_user

    if @answer.save
      redirect_to question_path(@question, anchor: "answer-#{@answer.id}"),
                  notice: "Answer posted successfully.", status: :see_other
    else
      # Re-render the question page with the error
      @answers = @question.answers.by_votes.includes(:user, comments: [ :user, { replies: :user } ])
      @question_comments = @question.comments.top_level.includes(:user, replies: [ :user, { replies: :user } ]).recent
      render "questions/show", status: :unprocessable_entity
    end
  end

  def edit
    @question = @answer.question
  end

  def update
    if @answer.update(answer_params)
      @answer.record_edit!(current_user)
      redirect_to question_path(@answer.question, anchor: "answer-#{@answer.id}"),
                  notice: "Answer updated successfully.", status: :see_other
    else
      @question = @answer.question
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @answer.soft_delete!
    redirect_to question_path(@answer.question, anchor: "answer-#{@answer.id}"),
                notice: "Answer deleted.", status: :see_other
  end

  def hard_delete
    question = @answer.question
    @answer.destroy!
    redirect_to question_path(question),
                notice: "Answer permanently deleted.", status: :see_other
  end

  def upvote
    @answer.upvote_by(current_user)
    respond_to_vote
  end

  def downvote
    @answer.downvote_by(current_user)
    respond_to_vote
  end

  def remove_vote
    @answer.remove_vote_by(current_user)
    respond_to_vote
  end

  private

  def set_question
    @question = Question.find(params[:question_id])
  end

  def set_answer
    @answer = Answer.find(params[:id])
  end

  def answer_params
    params.require(:answer).permit(:body)
  end

  def authorize_owner!
    return if @answer.owned_by?(current_user)

    redirect_to question_path(@answer.question), alert: "You can only edit or delete your own answers."
  end

  def authorize_moderator!
    return if current_user.can_moderate?(@answer.space)

    redirect_to question_path(@answer.question), alert: "Only moderators can permanently delete content."
  end

  def respond_to_vote
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "answer-#{@answer.id}-votes",
          partial: "votes/vote_buttons",
          locals: { votable: @answer, votable_type: "answer" }
        )
      end
      format.html { redirect_to @answer.question }
    end
  end
end
