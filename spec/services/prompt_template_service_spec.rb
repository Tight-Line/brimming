# frozen_string_literal: true

require "rails_helper"

RSpec.describe PromptTemplateService do
  describe ".load" do
    it "loads a template file" do
      template = described_class.load("ai_answer_rag.md")

      expect(template).to include("You are a helpful assistant")
      expect(template).to include("{{QUERY}}")
    end

    it "resolves partials in templates" do
      template = described_class.load("ai_answer_rag.md")

      # Should have resolved the markdown formatting rules partial
      expect(template).to include("Markdown Formatting Rules")
      expect(template).to include("ALWAYS include a blank line before starting a numbered or bulleted list")
      # Should not contain the partial include syntax
      expect(template).not_to include("{{> _markdown_formatting_rules}}")
    end

    it "resolves citation instructions partial" do
      template = described_class.load("ai_answer_rag.md")

      expect(template).to include("Cite sources inline")
      expect(template).to include("Example of good inline citations")
      expect(template).not_to include("{{> _citation_instructions}}")
    end

    it "raises error for non-existent file" do
      expect { described_class.load("nonexistent.md") }.to raise_error(Errno::ENOENT)
    end
  end

  describe ".interpolate" do
    it "replaces variables with values" do
      template = "Hello {{NAME}}, welcome to {{PLACE}}!"
      result = described_class.interpolate(template, {
        "NAME" => "Alice",
        "PLACE" => "Wonderland"
      })

      expect(result).to eq("Hello Alice, welcome to Wonderland!")
    end

    it "handles missing variables gracefully (leaves them as-is)" do
      template = "Hello {{NAME}}!"
      result = described_class.interpolate(template, {})

      expect(result).to eq("Hello {{NAME}}!")
    end

    it "converts non-string values to strings" do
      template = "Count: {{COUNT}}"
      result = described_class.interpolate(template, { "COUNT" => 42 })

      expect(result).to eq("Count: 42")
    end

    it "does not modify the original template" do
      template = "Hello {{NAME}}!"
      described_class.interpolate(template, { "NAME" => "World" })

      expect(template).to eq("Hello {{NAME}}!")
    end
  end

  describe ".render" do
    it "loads and interpolates in one step" do
      result = described_class.render("ai_answer_fallback.md", {
        "QUERY" => "How do I test?"
      })

      expect(result).to include("How do I test?")
      expect(result).to include("You are a helpful assistant")
      expect(result).not_to include("{{QUERY}}")
    end

    it "resolves partials before interpolation" do
      result = described_class.render("ai_answer_rag.md", {
        "QUERY" => "Test query",
        "RAG_CONTEXT" => "Some context here"
      })

      # Partials should be resolved
      expect(result).to include("Markdown Formatting Rules")
      # Variables should be interpolated
      expect(result).to include("Test query")
      expect(result).to include("Some context here")
    end
  end

  describe "partial resolution" do
    it "raises error for non-existent partial" do
      # Create a temp template with a bad partial reference
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read)
        .with(Rails.root.join("config/prompts/test_bad_partial.md"))
        .and_return("{{> _nonexistent_partial}}")

      expect {
        described_class.load("test_bad_partial.md")
      }.to raise_error(ArgumentError, /Partial not found/)
    end
  end
end
