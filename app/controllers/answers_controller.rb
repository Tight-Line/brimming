# frozen_string_literal: true

class AnswersController < ApplicationController
  before_action :require_login, only: [ :upvote, :downvote, :remove_vote ]
  before_action :set_answer

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

  def set_answer
    @answer = Answer.find(params[:id])
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
