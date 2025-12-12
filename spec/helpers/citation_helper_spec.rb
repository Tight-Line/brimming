# frozen_string_literal: true

require "rails_helper"

RSpec.describe CitationHelper do
  describe "#citation_converter_js" do
    it "returns empty string for nil sources" do
      expect(helper.citation_converter_js(nil)).to eq("")
    end

    it "returns empty string for empty sources" do
      expect(helper.citation_converter_js([])).to eq("")
    end

    it "generates JavaScript with source data" do
      sources = [
        { number: 1, type: "Article", id: 123, title: "Test Article" }
      ]

      result = helper.citation_converter_js(sources)

      expect(result).to include("window.CitationHelper")
      expect(result).to include("sources")
      expect(result).to include("convertInlineCitations")
      expect(result).to include("renderSourcesList")
      expect(result).to include("Test Article")
    end

    it "includes the citation SVG icon" do
      sources = [ { number: 1, type: "Article", id: 1, title: "Title" } ]

      result = helper.citation_converter_js(sources)

      expect(result).to include("citation-icon")
      expect(result).to include("viewBox")
    end

    it "escapes JSON properly" do
      sources = [
        { number: 1, type: "Article", id: 1, title: 'Title with "quotes"' }
      ]

      result = helper.citation_converter_js(sources)

      # Should be valid JavaScript (no syntax errors from unescaped quotes)
      expect(result).to include('Title with \\"quotes\\"')
    end

    it "includes escapeHtml function" do
      sources = [ { number: 1, type: "Article", id: 1, title: "Title" } ]

      result = helper.citation_converter_js(sources)

      expect(result).to include("escapeHtml")
    end

    it "handles Question type sources" do
      sources = [
        { number: 1, type: "Question", id: 456, title: "Test Question" }
      ]

      result = helper.citation_converter_js(sources)

      expect(result).to include("/questions/")
      expect(result).to include("Test Question")
    end

    it "returns html_safe string" do
      sources = [ { number: 1, type: "Article", id: 1, title: "Title" } ]

      result = helper.citation_converter_js(sources)

      expect(result).to be_html_safe
    end
  end

  describe "CITATION_ICON_SVG" do
    it "contains valid SVG markup" do
      expect(CitationHelper::CITATION_ICON_SVG).to include("<svg")
      expect(CitationHelper::CITATION_ICON_SVG).to include("</svg>")
      expect(CitationHelper::CITATION_ICON_SVG).to include("citation-icon")
    end
  end
end
