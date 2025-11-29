# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionPolicy do
  let(:space) { create(:space) }
  let(:owner) { create(:user) }
  let(:question) { create(:question, user: owner, space: space) }

  def policy(user)
    described_class.new(user, question)
  end

  describe "for visitors (no user)" do
    let(:user) { nil }

    it "allows index" do
      expect(policy(user).index?).to be true
    end

    it "allows show" do
      expect(policy(user).show?).to be true
    end

    it "denies create" do
      expect(policy(user).create?).to be_falsey
    end

    it "denies update" do
      expect(policy(user).update?).to be_falsey
    end

    it "denies destroy" do
      expect(policy(user).destroy?).to be_falsey
    end

    it "denies hard_delete" do
      expect(policy(user).hard_delete?).to be_falsey
    end

    it "denies vote" do
      expect(policy(user).vote?).to be_falsey
    end
  end

  describe "for regular users (not owner)" do
    let(:user) { create(:user) }

    it "allows index" do
      expect(policy(user).index?).to be true
    end

    it "allows show" do
      expect(policy(user).show?).to be true
    end

    it "allows create" do
      expect(policy(user).create?).to be true
    end

    it "denies update" do
      expect(policy(user).update?).to be false
    end

    it "denies destroy" do
      expect(policy(user).destroy?).to be false
    end

    it "denies hard_delete" do
      expect(policy(user).hard_delete?).to be false
    end

    it "allows vote" do
      expect(policy(user).vote?).to be true
    end
  end

  describe "for the owner" do
    it "allows index" do
      expect(policy(owner).index?).to be true
    end

    it "allows show" do
      expect(policy(owner).show?).to be true
    end

    it "allows create" do
      expect(policy(owner).create?).to be true
    end

    it "allows update" do
      expect(policy(owner).update?).to be true
    end

    it "allows destroy" do
      expect(policy(owner).destroy?).to be true
    end

    it "denies hard_delete" do
      expect(policy(owner).hard_delete?).to be false
    end

    it "allows vote" do
      expect(policy(owner).vote?).to be true
    end
  end

  describe "for space moderators" do
    let(:moderator) { create(:user) }

    before { space.add_moderator(moderator) }

    it "denies update (not owner)" do
      expect(policy(moderator).update?).to be false
    end

    it "denies destroy (not owner)" do
      expect(policy(moderator).destroy?).to be false
    end

    it "allows hard_delete" do
      expect(policy(moderator).hard_delete?).to be true
    end
  end

  describe "for admins" do
    let(:admin) { create(:user, :admin) }

    it "allows index" do
      expect(policy(admin).index?).to be true
    end

    it "allows show" do
      expect(policy(admin).show?).to be true
    end

    it "allows create" do
      expect(policy(admin).create?).to be true
    end

    it "denies update (not owner)" do
      expect(policy(admin).update?).to be false
    end

    it "denies destroy (not owner)" do
      expect(policy(admin).destroy?).to be false
    end

    it "allows hard_delete" do
      expect(policy(admin).hard_delete?).to be true
    end

    it "allows vote" do
      expect(policy(admin).vote?).to be true
    end
  end

  describe "Scope" do
    let(:user) { create(:user) }
    let!(:visible_question) { create(:question) }
    let!(:deleted_question) { create(:question, deleted_at: Time.current) }

    it "returns only non-deleted questions" do
      scope = described_class::Scope.new(user, Question).resolve
      expect(scope).to include(visible_question)
      expect(scope).not_to include(deleted_question)
    end

    it "works for visitors" do
      scope = described_class::Scope.new(nil, Question).resolve
      expect(scope).to include(visible_question)
      expect(scope).not_to include(deleted_question)
    end
  end
end
