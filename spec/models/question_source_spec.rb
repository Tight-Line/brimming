# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionSource do
  describe "associations" do
    it { is_expected.to belong_to(:question) }
  end

  describe "validations" do
    subject { build(:question_source) }

    it { is_expected.to validate_presence_of(:source_type) }
    it { is_expected.to validate_inclusion_of(:source_type).in_array(QuestionSource::SOURCE_TYPES) }
    it { is_expected.to validate_presence_of(:source_excerpt) }
  end

  describe "#source" do
    let(:question) { create(:question) }
    let(:article) { create(:article) }

    it "returns the associated record when source_id is present" do
      source = create(:question_source, question: question, source_type: "Article", source_id: article.id)
      expect(source.source).to eq(article)
    end

    it "returns nil when source_id is blank" do
      source = create(:question_source, question: question, source_type: "Upload", source_id: nil)
      expect(source.source).to be_nil
    end

    it "returns nil when record not found" do
      source = create(:question_source, question: question, source_type: "Article", source_id: 999_999)
      expect(source.source).to be_nil
    end
  end

  describe "#source=" do
    let(:question) { create(:question) }
    let(:article) { create(:article) }

    it "sets source_type and source_id from a record" do
      source = build(:question_source, question: question)
      source.source = article

      expect(source.source_type).to eq("Article")
      expect(source.source_id).to eq(article.id)
    end

    it "clears source_type and source_id when set to nil" do
      source = build(:question_source, question: question, source_type: "Article", source_id: 1)
      source.source = nil

      expect(source.source_type).to be_nil
      expect(source.source_id).to be_nil
    end
  end

  describe "#display_source_type" do
    it "returns human-readable source type names" do
      expect(build(:question_source, source_type: "Article").display_source_type).to eq("Article")
      expect(build(:question_source, source_type: "Chunk").display_source_type).to eq("Content Chunk")
      expect(build(:question_source, source_type: "Upload").display_source_type).to eq("Uploaded Document")
    end
  end

  describe "#excerpt_preview" do
    it "returns full excerpt when short" do
      source = build(:question_source, source_excerpt: "Short excerpt")
      expect(source.excerpt_preview).to eq("Short excerpt")
    end

    it "truncates long excerpts with ellipsis" do
      long_text = "A" * 300
      source = build(:question_source, source_excerpt: long_text)

      preview = source.excerpt_preview(length: 200)
      expect(preview.length).to eq(203) # 200 chars + "..."
      expect(preview).to end_with("...")
    end

    it "returns empty string for blank excerpt" do
      source = build(:question_source, source_excerpt: "placeholder")
      source.source_excerpt = nil
      expect(source.excerpt_preview).to eq("")
    end
  end
end
