# frozen_string_literal: true

class SpacesController < ApplicationController
  def index
    @spaces = Space.alphabetical
  end

  def show
    @space = Space.find_by!(slug: params[:id])
    @questions = @space.questions.recent.includes(:user)
  end
end
