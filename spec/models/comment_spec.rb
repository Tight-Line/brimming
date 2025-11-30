# frozen_string_literal: true

require "rails_helper"

RSpec.describe Comment do
  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_least(1).is_at_most(2000) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:commentable) }
    it { is_expected.to belong_to(:parent_comment).class_name("Comment").optional }
    it { is_expected.to belong_to(:last_editor).class_name("User").optional }
    it { is_expected.to have_many(:replies).class_name("Comment").dependent(:destroy) }
    it { is_expected.to have_many(:comment_votes).dependent(:destroy) }
  end

  describe "scopes" do
    describe ".top_level" do
      it "returns only comments without a parent" do
        question = create(:question)
        top_level = create(:comment, commentable: question)
        parent = create(:comment, commentable: question)
        create(:comment, parent_comment: parent, commentable: question)

        expect(described_class.top_level).to contain_exactly(top_level, parent)
      end
    end

    describe ".recent" do
      it "orders comments by created_at ascending" do
        old = create(:comment, created_at: 2.days.ago)
        new_comment = create(:comment, created_at: 1.day.ago)

        expect(described_class.recent).to eq([ old, new_comment ])
      end
    end

    describe ".by_votes" do
      it "orders comments by vote_score descending" do
        low = create(:comment, vote_score: 1)
        high = create(:comment, vote_score: 10)

        expect(described_class.by_votes).to eq([ high, low ])
      end
    end
  end

  describe "#author" do
    it "returns the user" do
      user = create(:user)
      comment = create(:comment, user: user)
      expect(comment.author).to eq(user)
    end
  end

  describe "#edited?" do
    it "returns false when edited_at is nil" do
      comment = create(:comment)
      expect(comment.edited?).to be false
    end

    it "returns true when edited_at is present" do
      comment = create(:comment, edited_at: Time.current)
      expect(comment.edited?).to be true
    end

    it "returns false even when updated_at differs from created_at" do
      comment = create(:comment, vote_score: 0)
      comment.increment!(:vote_score) # This updates updated_at but not edited_at
      expect(comment.edited?).to be false
    end
  end

  describe "#record_edit!" do
    let(:comment) { create(:comment) }
    let(:editor) { create(:user) }

    it "sets edited_at" do
      comment.record_edit!(editor)
      expect(comment.edited_at).to be_present
    end

    it "sets last_editor" do
      comment.record_edit!(editor)
      expect(comment.last_editor).to eq(editor)
    end
  end

  describe "#upvote_by" do
    let(:comment) { create(:comment, vote_score: 0) }
    let(:voter) { create(:user) }

    it "creates a vote" do
      comment.upvote_by(voter)
      expect(comment.comment_votes.find_by(user: voter)).to be_present
    end

    it "increases vote_score" do
      comment.upvote_by(voter)
      expect(comment.reload.vote_score).to eq(1)
    end

    it "does not allow duplicate votes" do
      comment.upvote_by(voter)
      comment.upvote_by(voter)
      expect(comment.reload.vote_score).to eq(1)
    end
  end

  describe "#remove_vote_by" do
    let(:comment) { create(:comment, vote_score: 1) }
    let(:voter) { create(:user) }

    before do
      create(:comment_vote, comment: comment, user: voter)
    end

    it "removes the vote" do
      comment.remove_vote_by(voter)
      expect(comment.comment_votes.find_by(user: voter)).to be_nil
    end

    it "decreases vote_score" do
      comment.remove_vote_by(voter)
      expect(comment.reload.vote_score).to eq(0)
    end

    it "does nothing if user hasn't voted" do
      other_user = create(:user)
      expect { comment.remove_vote_by(other_user) }.not_to(change { comment.reload.vote_score })
    end
  end

  describe "#voted_by?" do
    let(:comment) { create(:comment) }
    let(:voter) { create(:user) }

    it "returns true if user has voted" do
      create(:comment_vote, comment: comment, user: voter)
      expect(comment.voted_by?(voter)).to be true
    end

    it "returns false if user hasn't voted" do
      expect(comment.voted_by?(voter)).to be false
    end
  end

  describe "#owned_by?" do
    let(:user) { create(:user) }
    let(:comment) { create(:comment, user: user) }

    it "returns true for the owner" do
      expect(comment.owned_by?(user)).to be true
    end

    it "returns false for a different user" do
      other_user = create(:user)
      expect(comment.owned_by?(other_user)).to be false
    end

    it "returns false for nil" do
      expect(comment.owned_by?(nil)).to be false
    end
  end

  describe "#reply?" do
    it "returns true for replies" do
      comment = create(:comment, :reply)
      expect(comment.reply?).to be true
    end

    it "returns false for top-level comments" do
      comment = create(:comment)
      expect(comment.reply?).to be false
    end
  end

  describe "#depth" do
    it "returns 0 for top-level comments" do
      comment = create(:comment)
      expect(comment.depth).to eq(0)
    end

    it "returns 1 for direct replies" do
      parent = create(:comment)
      reply = create(:comment, parent_comment: parent, commentable: parent.commentable)
      expect(reply.depth).to eq(1)
    end

    it "returns 2 for nested replies" do
      grandparent = create(:comment)
      parent = create(:comment, parent_comment: grandparent, commentable: grandparent.commentable)
      child = create(:comment, parent_comment: parent, commentable: parent.commentable)
      expect(child.depth).to eq(2)
    end
  end

  describe "#allows_replies?" do
    it "returns true for comments below max depth" do
      comment = create(:comment)
      expect(comment.allows_replies?).to be true
    end

    it "returns true for comments at depth 2" do
      grandparent = create(:comment)
      parent = create(:comment, parent_comment: grandparent, commentable: grandparent.commentable)
      child = create(:comment, parent_comment: parent, commentable: parent.commentable)
      expect(child.allows_replies?).to be true
    end

    it "returns false for comments at max depth" do
      level0 = create(:comment)
      level1 = create(:comment, parent_comment: level0, commentable: level0.commentable)
      level2 = create(:comment, parent_comment: level1, commentable: level1.commentable)
      level3 = create(:comment, parent_comment: level2, commentable: level2.commentable)
      expect(level3.allows_replies?).to be false
    end

    it "returns false for deleted comments" do
      comment = create(:comment, deleted_at: Time.current)
      expect(comment.allows_replies?).to be false
    end
  end

  describe "#deleted?" do
    it "returns true when deleted_at is present" do
      comment = create(:comment, deleted_at: Time.current)
      expect(comment.deleted?).to be true
    end

    it "returns false when deleted_at is nil" do
      comment = create(:comment)
      expect(comment.deleted?).to be false
    end
  end

  describe "#soft_delete!" do
    it "sets deleted_at to current time" do
      comment = create(:comment)
      expect { comment.soft_delete! }.to change { comment.deleted? }.from(false).to(true)
    end
  end

  describe "polymorphic association" do
    it "can belong to a question" do
      question = create(:question)
      comment = create(:comment, commentable: question)
      expect(comment.commentable).to eq(question)
    end

    it "can belong to an answer" do
      answer = create(:answer)
      comment = create(:comment, commentable: answer)
      expect(comment.commentable).to eq(answer)
    end
  end

  describe "#space" do
    it "returns the space for a comment on a question" do
      space = create(:space)
      question = create(:question, space: space)
      comment = create(:comment, commentable: question)
      expect(comment.space).to eq(space)
    end

    it "returns the space for a comment on an answer" do
      space = create(:space)
      question = create(:question, space: space)
      answer = create(:answer, question: question)
      comment = create(:comment, commentable: answer)
      expect(comment.space).to eq(space)
    end
  end

  describe "#root_question" do
    it "returns the question for a comment on a question" do
      question = create(:question)
      comment = create(:comment, commentable: question)
      expect(comment.root_question).to eq(question)
    end

    it "returns the question for a comment on an answer" do
      question = create(:question)
      answer = create(:answer, question: question)
      comment = create(:comment, commentable: answer)
      expect(comment.root_question).to eq(question)
    end
  end

  describe "#root_question_id" do
    it "returns the question id for a comment on a question" do
      question = create(:question)
      comment = create(:comment, commentable: question)
      expect(comment.root_question_id).to eq(question.id)
    end

    it "returns the question id for a comment on an answer" do
      question = create(:question)
      answer = create(:answer, question: question)
      comment = create(:comment, commentable: answer)
      expect(comment.root_question_id).to eq(question.id)
    end
  end
end
