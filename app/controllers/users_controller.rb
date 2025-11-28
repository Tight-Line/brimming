# frozen_string_literal: true

class UsersController < ApplicationController
  def show
    @user = User.find_by!(username: params[:username])
    @recent_questions = @user.questions.recent.limit(5)
    @recent_answers = @user.answers.includes(:question).recent.limit(5)
  end
end
