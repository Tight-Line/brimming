# frozen_string_literal: true

require "rails_helper"

RSpec.describe Answer do
  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_least(10).is_at_most(10_000) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:question) }
    it { is_expected.to belong_to(:last_editor).class_name("User").optional }
    it { is_expected.to have_many(:votes).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
  end

  describe "scopes" do
    describe ".by_votes" do
      it "orders answers by vote_score descending" do
        question = create(:question)
        low = create(:answer, question: question, vote_score: 1)
        high = create(:answer, question: question, vote_score: 10)
        mid = create(:answer, question: question, vote_score: 5)

        expect(described_class.by_votes).to eq([ high, mid, low ])
      end
    end

    describe ".correct" do
      it "returns only correct answers" do
        correct = create(:answer, is_correct: true)
        create(:answer, is_correct: false)

        expect(described_class.correct).to eq([ correct ])
      end
    end

    describe ".recent" do
      it "orders answers by created_at descending" do
        old = create(:answer, created_at: 2.days.ago)
        new_answer = create(:answer, created_at: 1.day.ago)

        expect(described_class.recent).to eq([ new_answer, old ])
      end
    end
  end

  describe "#author" do
    it "returns the user" do
      user = create(:user)
      answer = create(:answer, user: user)
      expect(answer.author).to eq(user)
    end
  end

  describe "#mark_as_correct!" do
    let(:question) { create(:question) }
    let(:answer) { create(:answer, question: question) }

    it "marks the answer as correct" do
      answer.mark_as_correct!
      expect(answer.reload.is_correct).to be true
    end

    it "unmarks other correct answers for the same question" do
      other_answer = create(:answer, question: question, is_correct: true)
      answer.mark_as_correct!
      expect(other_answer.reload.is_correct).to be false
    end
  end

  describe "#unmark_as_correct!" do
    it "unmarks the answer as correct" do
      answer = create(:answer, is_correct: true)
      answer.unmark_as_correct!
      expect(answer.reload.is_correct).to be false
    end
  end

  describe "#upvote_by" do
    let(:answer) { create(:answer, vote_score: 0) }
    let(:voter) { create(:user) }

    it "creates an upvote" do
      answer.upvote_by(voter)
      vote = answer.votes.find_by(user: voter)
      expect(vote.value).to eq(1)
    end

    it "increases vote_score" do
      answer.upvote_by(voter)
      expect(answer.reload.vote_score).to eq(1)
    end

    it "changes a downvote to upvote" do
      create(:vote, answer: answer, user: voter, value: -1)
      answer.update!(vote_score: -1)
      answer.upvote_by(voter)
      expect(answer.reload.vote_score).to eq(1)
    end
  end

  describe "#downvote_by" do
    let(:answer) { create(:answer, vote_score: 0) }
    let(:voter) { create(:user) }

    it "creates a downvote" do
      answer.downvote_by(voter)
      vote = answer.votes.find_by(user: voter)
      expect(vote.value).to eq(-1)
    end

    it "decreases vote_score" do
      answer.downvote_by(voter)
      expect(answer.reload.vote_score).to eq(-1)
    end

    it "changes an upvote to downvote" do
      create(:vote, answer: answer, user: voter, value: 1)
      answer.update!(vote_score: 1)
      answer.downvote_by(voter)
      expect(answer.reload.vote_score).to eq(-1)
    end
  end

  describe "#remove_vote_by" do
    let(:answer) { create(:answer, vote_score: 1) }
    let(:voter) { create(:user) }

    before do
      create(:vote, answer: answer, user: voter, value: 1)
    end

    it "removes the vote" do
      answer.remove_vote_by(voter)
      expect(answer.votes.find_by(user: voter)).to be_nil
    end

    it "adjusts vote_score" do
      answer.remove_vote_by(voter)
      expect(answer.reload.vote_score).to eq(0)
    end

    it "does nothing if user hasn't voted" do
      other_user = create(:user)
      expect { answer.remove_vote_by(other_user) }.not_to(change { answer.reload.vote_score })
    end
  end

  describe "#vote_by" do
    let(:answer) { create(:answer) }
    let(:voter) { create(:user) }

    it "returns the vote by the user" do
      vote = create(:vote, answer: answer, user: voter)
      expect(answer.vote_by(voter)).to eq(vote)
    end

    it "returns nil if user hasn't voted" do
      expect(answer.vote_by(voter)).to be_nil
    end
  end

  describe "#owned_by?" do
    let(:user) { create(:user) }
    let(:answer) { create(:answer, user: user) }

    it "returns true for the owner" do
      expect(answer.owned_by?(user)).to be true
    end

    it "returns false for a different user" do
      other_user = create(:user)
      expect(answer.owned_by?(other_user)).to be false
    end

    it "returns false for nil" do
      expect(answer.owned_by?(nil)).to be false
    end
  end

  describe "#recalculate_vote_score!" do
    it "recalculates vote_score from votes" do
      answer = create(:answer, vote_score: 0)
      create(:vote, answer: answer, value: 1)
      create(:vote, answer: answer, value: 1)
      create(:vote, answer: answer, value: -1)

      answer.recalculate_vote_score!
      expect(answer.vote_score).to eq(1)
    end
  end

  describe "#edited?" do
    it "returns false when edited_at is nil" do
      answer = create(:answer)
      expect(answer.edited?).to be false
    end

    it "returns true when edited_at is present" do
      answer = create(:answer, edited_at: Time.current)
      expect(answer.edited?).to be true
    end
  end

  describe "#record_edit!" do
    let(:answer) { create(:answer) }
    let(:editor) { create(:user) }

    it "sets edited_at" do
      answer.record_edit!(editor)
      expect(answer.edited_at).to be_present
    end

    it "sets last_editor" do
      answer.record_edit!(editor)
      expect(answer.last_editor).to eq(editor)
    end
  end

  describe "comments" do
    let(:answer) { create(:answer) }

    it "can have comments" do
      comment = create(:comment, commentable: answer)
      expect(answer.comments).to include(comment)
    end
  end
end
