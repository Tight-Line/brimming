# frozen_string_literal: true

class AnswersController < ApplicationController
  before_action :require_login, only: [ :create, :upvote, :downvote, :remove_vote ]
  before_action :set_question, only: [ :create ]
  before_action :set_answer, only: [ :upvote, :downvote, :remove_vote ]

  def create
    @answer = @question.answers.build(answer_params)
    @answer.user = current_user

    if @answer.save
      redirect_to question_path(@question, anchor: "answer-#{@answer.id}"),
                  notice: "Answer posted successfully."
    else
      # Re-render the question page with the error
      @answers = @question.answers.by_votes.includes(:user, comments: [ :user, { replies: :user } ])
      @question_comments = @question.comments.top_level.includes(:user, replies: [ :user, { replies: :user } ]).recent
      render "questions/show", status: :unprocessable_entity
    end
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
