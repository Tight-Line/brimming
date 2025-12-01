# frozen_string_literal: true

require "rails_helper"

RSpec.describe Question do
  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_least(10).is_at_most(200) }

    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_least(20).is_at_most(10_000) }

    it { is_expected.to validate_presence_of(:slug) }

    describe "slug uniqueness" do
      subject { create(:question) }

      it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }
    end

    it "validates slug format" do
      question = build(:question, slug: "valid-slug-123")
      expect(question).to be_valid

      question.slug = "Invalid Slug!"
      expect(question).not_to be_valid
      expect(question.errors[:slug]).to include("can only contain lowercase letters, numbers, and hyphens")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:space) }
    it { is_expected.to belong_to(:last_editor).class_name("User").optional }
    it { is_expected.to have_many(:answers).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:question_votes).dependent(:destroy) }
    it { is_expected.to have_many(:question_tags).dependent(:destroy) }
    it { is_expected.to have_many(:tags).through(:question_tags) }
    it { is_expected.to have_many(:chunks).dependent(:destroy) }
  end

  describe "tags" do
    let(:space) { create(:space) }
    let(:question) { create(:question, space: space) }

    describe "validation" do
      it "allows up to 5 tags" do
        tags = create_list(:tag, 5, space: space)
        question.tags = tags
        expect(question).to be_valid
      end

      it "rejects more than 5 tags" do
        tags = create_list(:tag, 6, space: space)
        question.tags = tags
        expect(question).not_to be_valid
        expect(question.errors[:tags]).to include("cannot exceed 5")
      end

      it "requires tags to be from the same space" do
        other_space = create(:space)
        tag_from_other_space = create(:tag, space: other_space)
        # Build a question with an invalid tag assignment
        invalid_question = build(:question, space: space)
        invalid_question.tags = [ tag_from_other_space ]
        expect(invalid_question).not_to be_valid
        expect(invalid_question.errors[:tags]).to include("must belong to the same space as the question")
      end
    end

    describe "#tag_names" do
      it "returns an array of tag names" do
        tag1 = create(:tag, space: space, name: "ruby")
        tag2 = create(:tag, space: space, name: "rails")
        question.tags = [ tag1, tag2 ]
        expect(question.tag_names).to contain_exactly("ruby", "rails")
      end
    end
  end

  describe "slug generation" do
    it "generates a slug from the title" do
      question = create(:question, title: "How do I solve this problem?")
      expect(question.slug).to eq("how-do-i-solve-this-problem")
    end

    it "removes special characters from slug" do
      question = create(:question, title: "What's the best way to do this?!?")
      expect(question.slug).to eq("whats-the-best-way-to-do-this")
    end

    it "handles duplicate titles by appending a number" do
      create(:question, title: "How do I solve this problem?")
      question2 = create(:question, title: "How do I solve this problem?")
      expect(question2.slug).to eq("how-do-i-solve-this-problem-1")
    end

    it "truncates long titles" do
      long_title = "A" * 150 + " is this a good question?"
      question = create(:question, title: long_title)
      expect(question.slug.length).to be <= 80
    end

    it "does not regenerate slug on update" do
      question = create(:question, title: "Original title question here")
      original_slug = question.slug
      question.update!(title: "New updated title question here")
      expect(question.slug).to eq(original_slug)
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      question = create(:question, title: "How do I solve this problem?")
      expect(question.to_param).to eq(question.slug)
    end
  end

  describe "scopes" do
    describe ".not_deleted" do
      it "excludes soft-deleted questions" do
        active = create(:question)
        create(:question, deleted_at: Time.current)

        expect(described_class.not_deleted).to eq([ active ])
      end
    end

    describe ".recent" do
      it "orders questions by created_at descending" do
        old_question = create(:question, created_at: 2.days.ago)
        new_question = create(:question, created_at: 1.day.ago)

        expect(described_class.recent).to eq([ new_question, old_question ])
      end
    end

    describe ".by_space" do
      it "filters questions by space" do
        space = create(:space)
        other_space = create(:space)
        question_in_space = create(:question, space: space)
        create(:question, space: other_space)

        expect(described_class.by_space(space)).to eq([ question_in_space ])
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

  describe "#edited?" do
    it "returns false when edited_at is nil" do
      question = create(:question)
      expect(question.edited?).to be false
    end

    it "returns true when edited_at is present" do
      question = create(:question, edited_at: Time.current)
      expect(question.edited?).to be true
    end
  end

  describe "#record_edit!" do
    let(:question) { create(:question) }
    let(:editor) { create(:user) }

    it "sets edited_at" do
      question.record_edit!(editor)
      expect(question.edited_at).to be_present
    end

    it "sets last_editor" do
      question.record_edit!(editor)
      expect(question.last_editor).to eq(editor)
    end
  end

  describe "#increment_views!" do
    it "increments views_count" do
      question = create(:question, views_count: 5)
      question.increment_views!
      expect(question.reload.views_count).to eq(6)
    end
  end

  describe "comments" do
    let(:question) { create(:question) }

    it "can have comments" do
      comment = create(:comment, commentable: question)
      expect(question.comments).to include(comment)
    end
  end

  describe "#upvote_by" do
    let(:question) { create(:question, vote_score: 0) }
    let(:voter) { create(:user) }

    it "creates an upvote" do
      question.upvote_by(voter)
      vote = question.question_votes.find_by(user: voter)
      expect(vote.value).to eq(1)
    end

    it "increases vote_score" do
      question.upvote_by(voter)
      expect(question.reload.vote_score).to eq(1)
    end

    it "changes a downvote to upvote" do
      create(:question_vote, question: question, user: voter, value: -1)
      question.update!(vote_score: -1)
      question.upvote_by(voter)
      expect(question.reload.vote_score).to eq(1)
    end
  end

  describe "#downvote_by" do
    let(:question) { create(:question, vote_score: 0) }
    let(:voter) { create(:user) }

    it "creates a downvote" do
      question.downvote_by(voter)
      vote = question.question_votes.find_by(user: voter)
      expect(vote.value).to eq(-1)
    end

    it "decreases vote_score" do
      question.downvote_by(voter)
      expect(question.reload.vote_score).to eq(-1)
    end

    it "changes an upvote to downvote" do
      create(:question_vote, question: question, user: voter, value: 1)
      question.update!(vote_score: 1)
      question.downvote_by(voter)
      expect(question.reload.vote_score).to eq(-1)
    end
  end

  describe "#remove_vote_by" do
    let(:question) { create(:question, vote_score: 1) }
    let(:voter) { create(:user) }

    before do
      create(:question_vote, question: question, user: voter, value: 1)
    end

    it "removes the vote" do
      question.remove_vote_by(voter)
      expect(question.question_votes.find_by(user: voter)).to be_nil
    end

    it "adjusts vote_score" do
      question.remove_vote_by(voter)
      expect(question.reload.vote_score).to eq(0)
    end

    it "does nothing if user hasn't voted" do
      other_user = create(:user)
      expect { question.remove_vote_by(other_user) }.not_to(change { question.reload.vote_score })
    end
  end

  describe "#vote_by" do
    let(:question) { create(:question) }
    let(:voter) { create(:user) }

    it "returns the vote by the user" do
      vote = create(:question_vote, question: question, user: voter)
      expect(question.vote_by(voter)).to eq(vote)
    end

    it "returns nil if user hasn't voted" do
      expect(question.vote_by(voter)).to be_nil
    end
  end

  describe "#recalculate_vote_score!" do
    it "recalculates vote_score from votes" do
      question = create(:question, vote_score: 0)
      create(:question_vote, question: question, value: 1)
      create(:question_vote, question: question, value: 1)
      create(:question_vote, question: question, value: -1)

      question.recalculate_vote_score!
      expect(question.vote_score).to eq(1)
    end
  end

  describe "#deleted?" do
    it "returns true when deleted_at is present" do
      question = create(:question, deleted_at: Time.current)
      expect(question.deleted?).to be true
    end

    it "returns false when deleted_at is nil" do
      question = create(:question)
      expect(question.deleted?).to be false
    end
  end

  describe "#soft_delete!" do
    it "sets deleted_at to current time" do
      question = create(:question)
      expect { question.soft_delete! }.to change { question.deleted? }.from(false).to(true)
    end
  end
end
