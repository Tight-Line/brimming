# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Markdown" do
  describe "POST /markdown/preview" do
    it "renders markdown to HTML" do
      post markdown_preview_path, params: { text: "**bold** and *italic*" }, as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["html"]).to include("<strong>bold</strong>")
      expect(json["html"]).to include("<em>italic</em>")
    end

    it "renders code blocks with syntax highlighting" do
      code = "```ruby\nputs 'hello'\n```"
      post markdown_preview_path, params: { text: code }, as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["html"]).to include("highlight")
      expect(json["html"]).to include("ruby")
    end

    it "returns empty string for blank text" do
      post markdown_preview_path, params: { text: "" }, as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["html"]).to eq("")
    end
  end
end
