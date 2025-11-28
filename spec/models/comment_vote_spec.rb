# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommentVote do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:comment) }
  end

  describe "validations" do
    subject { create(:comment_vote) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:comment_id).with_message("has already voted on this comment") }
  end

  describe "uniqueness" do
    let(:user) { create(:user) }
    let(:comment) { create(:comment) }

    it "allows one vote per user per comment" do
      create(:comment_vote, user: user, comment: comment)
      duplicate = build(:comment_vote, user: user, comment: comment)
      expect(duplicate).not_to be_valid
    end

    it "allows same user to vote on different comments" do
      other_comment = create(:comment)
      create(:comment_vote, user: user, comment: comment)
      second_vote = build(:comment_vote, user: user, comment: other_comment)
      expect(second_vote).to be_valid
    end
  end
end
