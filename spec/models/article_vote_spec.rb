# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArticleVote do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:article) }
  end

  describe "validations" do
    subject { create(:article_vote) }

    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_inclusion_of(:value).in_array([ 1 ]) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:article_id).with_message("has already voted on this article") }

    it "rejects downvotes" do
      vote = build(:article_vote, value: -1)
      expect(vote).not_to be_valid
      expect(vote.errors[:value]).to include("is not included in the list")
    end
  end

  describe "#upvote?" do
    it "returns true for upvotes" do
      vote = build(:article_vote)
      expect(vote.upvote?).to be true
    end
  end
end
