# frozen_string_literal: true

require "rails_helper"

RSpec.describe Vote do
  describe "validations" do
    subject { build(:vote) }

    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_inclusion_of(:value).in_array([ -1, 1 ]) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:answer_id).with_message("has already voted on this answer") }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:answer) }
  end

  describe "scopes" do
    describe ".upvotes" do
      it "returns only upvotes" do
        upvote = create(:vote, :upvote)
        create(:vote, :downvote)

        expect(described_class.upvotes).to eq([ upvote ])
      end
    end

    describe ".downvotes" do
      it "returns only downvotes" do
        create(:vote, :upvote)
        downvote = create(:vote, :downvote)

        expect(described_class.downvotes).to eq([ downvote ])
      end
    end
  end

  describe "#upvote?" do
    it "returns true for upvotes" do
      vote = build(:vote, :upvote)
      expect(vote.upvote?).to be true
    end

    it "returns false for downvotes" do
      vote = build(:vote, :downvote)
      expect(vote.upvote?).to be false
    end
  end

  describe "#downvote?" do
    it "returns true for downvotes" do
      vote = build(:vote, :downvote)
      expect(vote.downvote?).to be true
    end

    it "returns false for upvotes" do
      vote = build(:vote, :upvote)
      expect(vote.downvote?).to be false
    end
  end
end
