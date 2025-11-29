# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :require_login, only: [ :search ]

  def show
    @user = User.find_by!(username: params[:username])
    @recent_questions = @user.questions.recent.limit(5)
    @recent_answers = @user.answers.includes(:question).recent.limit(5)
  end

  def search
    users = User.search(params[:q])

    # Optionally exclude certain user IDs (e.g., existing moderators)
    if params[:exclude].present?
      exclude_ids = params[:exclude].split(",").map(&:to_i)
      users = users.where.not(id: exclude_ids)
    end

    render json: users.map { |u|
      {
        id: u.id,
        username: u.username,
        display_name: u.display_name
      }
    }
  end
end
