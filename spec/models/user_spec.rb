# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value("user@example.com").for(:email) }
    it { is_expected.not_to allow_value("invalid-email").for(:email) }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
    it { is_expected.to validate_length_of(:username).is_at_least(3).is_at_most(30) }
    it { is_expected.to allow_value("valid_user123").for(:username) }
    it { is_expected.not_to allow_value("invalid user").for(:username) }
    it { is_expected.not_to allow_value("user@name").for(:username) }

    it { is_expected.to validate_presence_of(:role) }
  end

  describe "associations" do
    it { is_expected.to have_many(:questions).dependent(:destroy) }
    it { is_expected.to have_many(:answers).dependent(:destroy) }
    it { is_expected.to have_many(:votes).dependent(:destroy) }
    it { is_expected.to have_many(:question_votes).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:comment_votes).dependent(:destroy) }
    it { is_expected.to have_many(:space_subscriptions).dependent(:destroy) }
    it { is_expected.to have_many(:subscribed_spaces).through(:space_subscriptions).source(:space) }
    it { is_expected.to have_many(:space_moderators).dependent(:destroy) }
    it { is_expected.to have_many(:moderated_spaces).through(:space_moderators).source(:space) }
  end

  describe "enums" do
    # Note: moderator is per-space via SpaceModerator, not a global role
    it { is_expected.to define_enum_for(:role).with_values(user: 0, admin: 2) }
  end

  describe "callbacks" do
    describe "before_validation :normalize_email" do
      it "downcases and strips email" do
        user = build(:user, email: "  USER@EXAMPLE.COM  ")
        user.valid?
        expect(user.email).to eq("user@example.com")
      end
    end
  end

  describe "#to_param" do
    it "returns the username" do
      user = build(:user, username: "testuser")
      expect(user.to_param).to eq("testuser")
    end
  end

  describe "#display_name" do
    it "returns full_name when present" do
      user = build(:user, username: "testuser", full_name: "Test User")
      expect(user.display_name).to eq("Test User")
    end

    it "returns username when full_name is blank" do
      user = build(:user, username: "testuser", full_name: nil)
      expect(user.display_name).to eq("testuser")
    end

    it "returns username when full_name is empty string" do
      user = build(:user, username: "testuser", full_name: "")
      expect(user.display_name).to eq("testuser")
    end
  end

  describe "#has_solved_answer?" do
    it "returns true when user has a solved answer" do
      user = create(:user)
      create(:answer, user: user, is_correct: true)
      expect(user.has_solved_answer?).to be true
    end

    it "returns false when user has no solved answers" do
      user = create(:user)
      create(:answer, user: user, is_correct: false)
      expect(user.has_solved_answer?).to be false
    end

    it "returns false when user has no answers" do
      user = create(:user)
      expect(user.has_solved_answer?).to be false
    end
  end

  describe "#admin?" do
    it "returns true for admin users" do
      user = build(:user, :admin)
      expect(user.admin?).to be true
    end

    it "returns false for non-admin users" do
      user = build(:user)
      expect(user.admin?).to be false
    end
  end

  describe "#moderator?" do
    it "returns true for users who moderate at least one space" do
      user = create(:user)
      space = create(:space)
      space.add_moderator(user)
      expect(user.moderator?).to be true
    end

    it "returns false for users who moderate no spaces" do
      user = create(:user)
      expect(user.moderator?).to be false
    end
  end

  describe "#can_moderate?" do
    let(:space) { create(:space) }
    let(:user) { create(:user) }

    it "returns true for admin users" do
      admin = create(:user, :admin)
      expect(admin.can_moderate?(space)).to be true
    end

    it "returns true for space moderators" do
      create(:space_moderator, space: space, user: user)
      expect(user.can_moderate?(space)).to be true
    end

    it "returns false for regular users" do
      expect(user.can_moderate?(space)).to be false
    end
  end

  describe "#questions_count" do
    it "returns the count of user's questions" do
      user = create(:user)
      create_list(:question, 3, user: user)
      expect(user.questions_count).to eq(3)
    end
  end

  describe "#answers_count" do
    it "returns the count of user's answers" do
      user = create(:user)
      create_list(:answer, 5, user: user)
      expect(user.answers_count).to eq(5)
    end
  end

  describe "#solved_answers_count" do
    it "returns the count of user's answers marked as solved by moderators" do
      user = create(:user)
      create_list(:answer, 3, user: user, is_correct: false)
      create_list(:answer, 2, user: user, is_correct: true)
      expect(user.solved_answers_count).to eq(2)
    end
  end

  describe "#best_answers_count" do
    it "returns 0 when user has no answers" do
      user = create(:user)
      expect(user.best_answers_count).to eq(0)
    end

    it "returns count of user's highest-voted answers per question" do
      user = create(:user)
      other_user = create(:user)
      question1 = create(:question)
      question2 = create(:question)

      # User has highest-voted answer on question1
      create(:answer, question: question1, user: user, vote_score: 10)
      create(:answer, question: question1, user: other_user, vote_score: 5)

      # Other user has highest-voted answer on question2
      create(:answer, question: question2, user: user, vote_score: 3)
      create(:answer, question: question2, user: other_user, vote_score: 8)

      expect(user.best_answers_count).to eq(1)
    end

    it "counts multiple best answers across different questions" do
      user = create(:user)
      other_user = create(:user)
      question1 = create(:question)
      question2 = create(:question)
      question3 = create(:question)

      # User has highest-voted on question1 and question2
      create(:answer, question: question1, user: user, vote_score: 10)
      create(:answer, question: question2, user: user, vote_score: 5)
      create(:answer, question: question3, user: other_user, vote_score: 20)

      expect(user.best_answers_count).to eq(2)
    end

    it "uses oldest answer as tiebreaker when vote scores are equal" do
      user = create(:user)
      other_user = create(:user)
      question = create(:question)

      # Other user's answer is older but same score - they win
      create(:answer, question: question, user: other_user, vote_score: 5, created_at: 2.days.ago)
      create(:answer, question: question, user: user, vote_score: 5, created_at: 1.day.ago)

      expect(user.best_answers_count).to eq(0)
      expect(other_user.best_answers_count).to eq(1)
    end
  end

  describe "#comments_count" do
    it "returns the count of user's comments" do
      user = create(:user)
      question = create(:question)
      create_list(:comment, 4, user: user, commentable: question)
      expect(user.comments_count).to eq(4)
    end
  end

  describe "#karma" do
    it "returns 0 for a user with no activity" do
      user = create(:user)
      expect(user.karma).to eq(0)
    end

    it "includes karma from questions" do
      user = create(:user)
      create(:question, user: user, vote_score: 5)
      # 5 (base for question) + 5 (vote score) = 10
      expect(user.karma).to eq(10)
    end

    it "includes karma from answers" do
      user = create(:user)
      create(:answer, user: user, vote_score: 3)
      # 10 (base for answer) + 3 (vote score) = 13
      expect(user.karma).to eq(13)
    end

    it "includes bonus karma for solved answers" do
      user = create(:user)
      create(:answer, user: user, is_correct: true, vote_score: 0)
      # 10 (base for answer) + 15 (solved bonus) + 0 (vote score) = 25
      expect(user.karma).to eq(25)
    end

    it "includes karma from comments" do
      user = create(:user)
      question = create(:question)
      create(:comment, user: user, commentable: question, vote_score: 2)
      # 0 (no questions/answers) + 2 (comment vote score) = 2
      expect(user.karma).to eq(2)
    end

    it "calculates total karma from all sources" do
      user = create(:user)
      question = create(:question)
      create(:question, user: user, vote_score: 10)       # 5 + 10 = 15
      create(:answer, user: user, is_correct: true, vote_score: 5) # 10 + 15 + 5 = 30
      create(:answer, user: user, is_correct: false, vote_score: 3) # 10 + 3 = 13
      create(:comment, user: user, commentable: question, vote_score: 2) # 2
      # Total: 15 + 30 + 13 + 2 = 60
      expect(user.karma).to eq(60)
    end
  end
end
