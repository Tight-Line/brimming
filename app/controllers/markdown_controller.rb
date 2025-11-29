# frozen_string_literal: true

class MarkdownController < ApplicationController
  include MarkdownHelper

  def preview
    text = params[:text].to_s
    html = markdown(text)
    render json: { html: html }
  end
end
