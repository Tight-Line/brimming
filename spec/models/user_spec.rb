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
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(user: 0, moderator: 1, admin: 2) }
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

  describe "#display_name" do
    it "returns the username" do
      user = build(:user, username: "testuser")
      expect(user.display_name).to eq("testuser")
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
    it "returns true for moderator users" do
      user = build(:user, :moderator)
      expect(user.moderator?).to be true
    end

    it "returns false for non-moderator users" do
      user = build(:user)
      expect(user.moderator?).to be false
    end
  end

  describe "#can_moderate?" do
    let(:category) { create(:category) }
    let(:user) { create(:user) }

    it "returns true for admin users" do
      admin = create(:user, :admin)
      expect(admin.can_moderate?(category)).to be true
    end

    it "returns true for category moderators" do
      create(:category_moderator, category: category, user: user)
      expect(user.can_moderate?(category)).to be true
    end

    it "returns false for regular users" do
      expect(user.can_moderate?(category)).to be false
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

  describe "#best_answers_count" do
    it "returns the count of user's correct answers" do
      user = create(:user)
      create_list(:answer, 3, user: user, is_correct: false)
      create_list(:answer, 2, user: user, is_correct: true)
      expect(user.best_answers_count).to eq(2)
    end
  end
end
