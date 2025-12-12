# frozen_string_literal: true

class MarkdownController < ApplicationController
  include MarkdownHelper

  # POST /markdown/preview - used by Q&A Wizard and AI Answer
  def preview
    text = params[:text].to_s
    html = markdown(text)
    render json: { html: html }
  end
end
