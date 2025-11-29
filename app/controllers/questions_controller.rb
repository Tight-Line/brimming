# frozen_string_literal: true

class QuestionsController < ApplicationController
  before_action :require_login, only: [ :upvote, :downvote, :remove_vote ]
  before_action :set_question, only: [ :show, :upvote, :downvote, :remove_vote ]

  def index
    @questions = Question.recent.includes(:user, :space)
    @questions = @questions.by_space(Space.find_by(slug: params[:space])) if params[:space].present?
  end

  def show
    @answers = @question.answers.by_votes.includes(:user, comments: [ :user, { replies: :user } ])
    @question_comments = @question.comments.top_level.includes(:user, replies: [ :user, { replies: :user } ]).recent
  end

  def upvote
    @question.upvote_by(current_user)
    respond_to_vote
  end

  def downvote
    @question.downvote_by(current_user)
    respond_to_vote
  end

  def remove_vote
    @question.remove_vote_by(current_user)
    respond_to_vote
  end

  private

  def set_question
    @question = Question.find(params[:id])
  end

  def respond_to_vote
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "question-#{@question.id}-votes",
          partial: "votes/vote_buttons",
          locals: { votable: @question, votable_type: "question" }
        )
      end
      format.html { redirect_to @question }
    end
  end
end
