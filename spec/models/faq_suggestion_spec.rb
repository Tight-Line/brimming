# frozen_string_literal: true

require "rails_helper"

RSpec.describe FaqSuggestion do
  describe "associations" do
    it { is_expected.to belong_to(:space) }
    it { is_expected.to belong_to(:created_by).class_name("User") }
  end

  describe "validations" do
    subject { build(:faq_suggestion) }

    it { is_expected.to validate_presence_of(:batch_id) }
    it { is_expected.to validate_presence_of(:source_type) }
    it { is_expected.to validate_inclusion_of(:source_type).in_array(FaqSuggestion::SOURCE_TYPES) }
    it { is_expected.to validate_presence_of(:question_text) }
    it { is_expected.to validate_length_of(:question_text).is_at_least(10).is_at_most(200) }
    it { is_expected.to validate_length_of(:question_body).is_at_most(5000) }
    it { is_expected.to allow_value(nil).for(:question_body) }
    it { is_expected.to allow_value("").for(:question_body) }
    it { is_expected.to validate_presence_of(:answer_text) }
    it { is_expected.to validate_length_of(:answer_text).is_at_least(20).is_at_most(10_000) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(FaqSuggestion::STATUSES) }
  end

  describe "scopes" do
    let(:space) { create(:space) }
    let(:user) { create(:user) }
    let(:batch_id) { SecureRandom.uuid }

    describe ".pending" do
      it "returns only pending suggestions" do
        pending = create(:faq_suggestion, :pending, space: space, created_by: user)
        _approved = create(:faq_suggestion, :approved, space: space, created_by: user)

        expect(FaqSuggestion.pending).to eq([ pending ])
      end
    end

    describe ".approved" do
      it "returns only approved suggestions" do
        _pending = create(:faq_suggestion, :pending, space: space, created_by: user)
        approved = create(:faq_suggestion, :approved, space: space, created_by: user)

        expect(FaqSuggestion.approved).to eq([ approved ])
      end
    end

    describe ".for_batch" do
      it "returns suggestions for a specific batch" do
        batch1 = create(:faq_suggestion, batch_id: batch_id, space: space, created_by: user)
        _batch2 = create(:faq_suggestion, batch_id: SecureRandom.uuid, space: space, created_by: user)

        expect(FaqSuggestion.for_batch(batch_id)).to eq([ batch1 ])
      end
    end

    describe ".stale" do
      it "returns suggestions older than 7 days that are not created" do
        stale_pending = create(:faq_suggestion, :pending, space: space, created_by: user, created_at: 8.days.ago)
        _fresh_pending = create(:faq_suggestion, :pending, space: space, created_by: user, created_at: 1.day.ago)
        _stale_created = create(:faq_suggestion, :created, space: space, created_by: user, created_at: 8.days.ago)

        expect(FaqSuggestion.stale).to eq([ stale_pending ])
      end
    end
  end

  describe "status methods" do
    let(:suggestion) { build(:faq_suggestion) }

    describe "#pending?" do
      it "returns true when status is pending" do
        suggestion.status = "pending"
        expect(suggestion.pending?).to be true
      end

      it "returns false for other statuses" do
        suggestion.status = "approved"
        expect(suggestion.pending?).to be false
      end
    end

    describe "#approved?" do
      it "returns true when status is approved" do
        suggestion.status = "approved"
        expect(suggestion.approved?).to be true
      end
    end

    describe "#rejected?" do
      it "returns true when status is rejected" do
        suggestion.status = "rejected"
        expect(suggestion.rejected?).to be true
      end
    end

    describe "#created?" do
      it "returns true when status is created" do
        suggestion.status = "created"
        expect(suggestion.created?).to be true
      end
    end
  end

  describe "status transitions" do
    let(:suggestion) { create(:faq_suggestion, :pending) }

    describe "#approve!" do
      it "changes status to approved" do
        suggestion.approve!
        expect(suggestion.reload.status).to eq("approved")
      end
    end

    describe "#reject!" do
      it "changes status to rejected" do
        suggestion.reject!
        expect(suggestion.reload.status).to eq("rejected")
      end
    end

    describe "#mark_created!" do
      it "changes status to created" do
        suggestion.mark_created!
        expect(suggestion.reload.status).to eq("created")
      end
    end
  end

  describe "#source_excerpts" do
    it "parses JSON source_context" do
      suggestion = build(:faq_suggestion, source_context: [ { article_id: 1 }, { article_id: 2 } ].to_json)
      expect(suggestion.source_excerpts).to eq([ { "article_id" => 1 }, { "article_id" => 2 } ])
    end

    it "returns array with raw string for invalid JSON" do
      suggestion = build(:faq_suggestion, source_context: "not json")
      expect(suggestion.source_excerpts).to eq([ "not json" ])
    end

    it "returns empty array for blank context" do
      suggestion = build(:faq_suggestion, source_context: nil)
      expect(suggestion.source_excerpts).to eq([])
    end
  end

  describe "#source_excerpts=" do
    it "converts array to JSON" do
      suggestion = build(:faq_suggestion)
      suggestion.source_excerpts = [ { article_id: 1 } ]
      expect(suggestion.source_context).to eq('[{"article_id":1}]')
    end
  end

  describe "#display_source_type" do
    it "returns human-readable source type names" do
      expect(build(:faq_suggestion, source_type: "article").display_source_type).to eq("Article")
      expect(build(:faq_suggestion, source_type: "upload").display_source_type).to eq("Uploaded Document")
      expect(build(:faq_suggestion, source_type: "manual").display_source_type).to eq("Manual Entry")
      expect(build(:faq_suggestion, source_type: "rag").display_source_type).to eq("Knowledge Base")
    end
  end
end
