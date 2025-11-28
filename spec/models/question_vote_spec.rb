# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionVote do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:question) }
  end

  describe "validations" do
    subject { create(:question_vote) }

    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_inclusion_of(:value).in_array([ -1, 1 ]) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:question_id).with_message("has already voted on this question") }
  end

  describe "scopes" do
    describe ".upvotes" do
      it "returns only upvotes" do
        upvote = create(:question_vote, :upvote)
        create(:question_vote, :downvote)

        expect(described_class.upvotes).to eq([ upvote ])
      end
    end

    describe ".downvotes" do
      it "returns only downvotes" do
        create(:question_vote, :upvote)
        downvote = create(:question_vote, :downvote)

        expect(described_class.downvotes).to eq([ downvote ])
      end
    end
  end

  describe "#upvote?" do
    it "returns true for upvotes" do
      vote = build(:question_vote, :upvote)
      expect(vote.upvote?).to be true
    end

    it "returns false for downvotes" do
      vote = build(:question_vote, :downvote)
      expect(vote.upvote?).to be false
    end
  end

  describe "#downvote?" do
    it "returns true for downvotes" do
      vote = build(:question_vote, :downvote)
      expect(vote.downvote?).to be true
    end

    it "returns false for upvotes" do
      vote = build(:question_vote, :upvote)
      expect(vote.downvote?).to be false
    end
  end
end
