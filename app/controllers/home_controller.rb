# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @recent_questions = Question.not_deleted.recent.includes(:user, :space).limit(10)
    @spaces = Space.alphabetical
  end
end
