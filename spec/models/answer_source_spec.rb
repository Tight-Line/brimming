# frozen_string_literal: true

require "rails_helper"

RSpec.describe AnswerSource do
  subject(:answer_source) { build(:answer_source) }

  describe "associations" do
    it { is_expected.to belong_to(:answer) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:source_type) }
    it { is_expected.to validate_inclusion_of(:source_type).in_array(AnswerSource::SOURCE_TYPES) }
    it { is_expected.to validate_presence_of(:source_excerpt) }
  end

  describe "#source" do
    context "when source_id is blank" do
      it "returns nil" do
        answer_source.source_id = nil
        expect(answer_source.source).to be_nil
      end
    end

    context "when source_id is present" do
      let(:article) { create(:article, user: answer_source.answer.user) }

      it "returns the source record" do
        answer_source.source_type = "Article"
        answer_source.source_id = article.id
        expect(answer_source.source).to eq(article)
      end
    end

    context "when source record does not exist" do
      it "returns nil" do
        answer_source.source_type = "Article"
        answer_source.source_id = 99999
        expect(answer_source.source).to be_nil
      end
    end
  end

  describe "#source=" do
    let(:article) { create(:article, user: answer_source.answer.user) }

    context "when setting a record" do
      it "sets source_type and source_id" do
        answer_source.source = article
        expect(answer_source.source_type).to eq("Article")
        expect(answer_source.source_id).to eq(article.id)
      end
    end

    context "when setting nil" do
      it "clears source_type and source_id" do
        answer_source.source_type = "Article"
        answer_source.source_id = article.id
        answer_source.source = nil
        expect(answer_source.source_type).to be_nil
        expect(answer_source.source_id).to be_nil
      end
    end
  end

  describe "#display_source_type" do
    it "returns human-readable source type" do
      answer_source.source_type = "Article"
      expect(answer_source.display_source_type).to eq("Article")
    end

    it "returns 'Content Chunk' for Chunk type" do
      answer_source.source_type = "Chunk"
      expect(answer_source.display_source_type).to eq("Content Chunk")
    end
  end

  describe "#excerpt_preview" do
    it "returns full excerpt when short" do
      answer_source.source_excerpt = "Short excerpt"
      expect(answer_source.excerpt_preview).to eq("Short excerpt")
    end

    it "truncates long excerpts" do
      answer_source.source_excerpt = "A" * 300
      expect(answer_source.excerpt_preview.length).to eq(203) # 200 + "..."
      expect(answer_source.excerpt_preview).to end_with("...")
    end

    it "returns empty string when excerpt is blank" do
      answer_source.source_excerpt = nil
      # Validation will fail, so temporarily allow nil for this test
      answer_source.instance_variable_set(:@source_excerpt, nil)
      allow(answer_source).to receive(:source_excerpt).and_return(nil)
      expect(answer_source.excerpt_preview).to eq("")
    end
  end

  describe "SOURCE_TYPES" do
    it "includes expected types" do
      expect(AnswerSource::SOURCE_TYPES).to include("Article", "Question", "Chunk", "Upload")
    end
  end
end
