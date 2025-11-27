# frozen_string_literal: true

require "rails_helper"

RSpec.describe Question do
  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_least(10).is_at_most(200) }

    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_least(20).is_at_most(10_000) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:category) }
    it { is_expected.to have_many(:answers).dependent(:destroy) }
  end

  describe "scopes" do
    describe ".recent" do
      it "orders questions by created_at descending" do
        old_question = create(:question, created_at: 2.days.ago)
        new_question = create(:question, created_at: 1.day.ago)

        expect(described_class.recent).to eq([ new_question, old_question ])
      end
    end

    describe ".by_category" do
      it "filters questions by category" do
        category = create(:category)
        other_category = create(:category)
        question_in_category = create(:question, category: category)
        create(:question, category: other_category)

        expect(described_class.by_category(category)).to eq([ question_in_category ])
      end
    end
  end

  describe "#author" do
    it "returns the user" do
      user = create(:user)
      question = create(:question, user: user)
      expect(question.author).to eq(user)
    end
  end

  describe "#answers_count" do
    it "returns the count of answers" do
      question = create(:question)
      create_list(:answer, 3, question: question)
      expect(question.answers_count).to eq(3)
    end
  end

  describe "#has_correct_answer?" do
    let(:question) { create(:question) }

    it "returns true when a correct answer exists" do
      create(:answer, question: question, is_correct: true)
      expect(question.has_correct_answer?).to be true
    end

    it "returns false when no correct answer exists" do
      create(:answer, question: question, is_correct: false)
      expect(question.has_correct_answer?).to be false
    end
  end

  describe "#correct_answer" do
    let(:question) { create(:question) }

    it "returns the correct answer" do
      correct = create(:answer, question: question, is_correct: true)
      create(:answer, question: question, is_correct: false)
      expect(question.correct_answer).to eq(correct)
    end

    it "returns nil when no correct answer exists" do
      create(:answer, question: question, is_correct: false)
      expect(question.correct_answer).to be_nil
    end
  end

  describe "#top_answers" do
    let(:question) { create(:question) }

    it "returns answers ordered by votes" do
      low_vote = create(:answer, question: question, vote_score: 1)
      high_vote = create(:answer, question: question, vote_score: 10)
      mid_vote = create(:answer, question: question, vote_score: 5)

      expect(question.top_answers).to eq([ high_vote, mid_vote, low_vote ])
    end

    it "limits the number of results" do
      create_list(:answer, 5, question: question)
      expect(question.top_answers(3).count).to eq(3)
    end
  end

  describe "#owned_by?" do
    let(:user) { create(:user) }
    let(:question) { create(:question, user: user) }

    it "returns true for the owner" do
      expect(question.owned_by?(user)).to be true
    end

    it "returns false for a different user" do
      other_user = create(:user)
      expect(question.owned_by?(other_user)).to be false
    end

    it "returns false for nil" do
      expect(question.owned_by?(nil)).to be false
    end
  end
end
