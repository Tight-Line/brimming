# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @recent_questions = Question.recent.includes(:user, :category).limit(10)
    @categories = Category.alphabetical
  end
end
