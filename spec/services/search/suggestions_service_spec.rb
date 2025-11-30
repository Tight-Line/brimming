# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search::SuggestionsService do
  let(:space) { create(:space) }

  describe "#call" do
    context "with blank query" do
      it "returns empty result" do
        result = described_class.new("").call

        expect(result[:questions]).to be_empty
      end

      it "returns empty for whitespace query" do
        result = described_class.new("   ").call

        expect(result[:questions]).to be_empty
      end
    end

    context "with valid query" do
      let!(:matching_question) { create(:question, space: space, title: "How to use Ruby on Rails?") }
      let!(:non_matching_question) { create(:question, space: space, title: "Python programming basics") }

      it "returns matching questions" do
        result = described_class.new("Ruby").call

        expect(result[:questions].length).to eq(1)
        expect(result[:questions].first[:title]).to eq("How to use Ruby on Rails?")
      end

      it "includes question metadata" do
        result = described_class.new("Ruby").call

        question = result[:questions].first
        expect(question[:id]).to eq(matching_question.id)
        expect(question[:slug]).to eq(matching_question.slug)
        expect(question[:space_slug]).to eq(space.slug)
      end
    end

    context "with space filter" do
      let(:other_space) { create(:space) }
      let!(:question_in_space) { create(:question, space: space, title: "Ruby in target space") }
      let!(:question_in_other_space) { create(:question, space: other_space, title: "Ruby in other space") }

      it "filters by space" do
        result = described_class.new("Ruby", space_id: space.id).call

        expect(result[:questions].length).to eq(1)
        expect(result[:questions].first[:id]).to eq(question_in_space.id)
      end
    end

    context "with many matching questions" do
      before do
        10.times { |i| create(:question, space: space, title: "Ruby question #{i}") }
      end

      it "limits to MAX_SUGGESTIONS" do
        result = described_class.new("Ruby").call

        expect(result[:questions].length).to be <= 5
      end
    end

    context "with fuzzy matching" do
      let!(:question) { create(:question, space: space, title: "Authentication with OAuth") }

      it "matches similar terms" do
        # pg_trgm provides fuzzy matching
        result = described_class.new("Authent").call

        expect(result[:questions]).not_to be_empty
      end
    end

    context "error handling" do
      it "handles errors gracefully" do
        allow(Question).to receive(:not_deleted).and_raise(StandardError.new("Database error"))

        result = described_class.new("ruby").call

        expect(result[:questions]).to be_empty
      end
    end
  end
end
