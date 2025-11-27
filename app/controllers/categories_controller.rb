# frozen_string_literal: true

class CategoriesController < ApplicationController
  def index
    @categories = Category.alphabetical
  end

  def show
    @category = Category.find_by!(slug: params[:id])
    @questions = @category.questions.recent.includes(:user)
  end
end
