# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpacePolicy do
  let(:space) { create(:space) }

  def policy(user)
    described_class.new(user, space)
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

    it "denies manage_moderators" do
      expect(policy(user).manage_moderators?).to be_falsey
    end
  end

  describe "for regular users" do
    let(:user) { create(:user) }

    it "allows index" do
      expect(policy(user).index?).to be true
    end

    it "allows show" do
      expect(policy(user).show?).to be true
    end

    it "denies create" do
      expect(policy(user).create?).to be false
    end

    it "denies update" do
      expect(policy(user).update?).to be false
    end

    it "denies destroy" do
      expect(policy(user).destroy?).to be false
    end

    it "denies manage_moderators" do
      expect(policy(user).manage_moderators?).to be false
    end
  end

  describe "for moderators of the space" do
    let(:user) { create(:user) }

    before { space.add_moderator(user) }

    it "allows index" do
      expect(policy(user).index?).to be true
    end

    it "allows show" do
      expect(policy(user).show?).to be true
    end

    it "denies create" do
      expect(policy(user).create?).to be false
    end

    it "denies update" do
      expect(policy(user).update?).to be false
    end

    it "denies destroy" do
      expect(policy(user).destroy?).to be false
    end

    it "allows manage_moderators" do
      expect(policy(user).manage_moderators?).to be true
    end
  end

  describe "for admins" do
    let(:user) { create(:user, :admin) }

    it "allows index" do
      expect(policy(user).index?).to be true
    end

    it "allows show" do
      expect(policy(user).show?).to be true
    end

    it "allows create" do
      expect(policy(user).create?).to be true
    end

    it "allows update" do
      expect(policy(user).update?).to be true
    end

    it "allows destroy" do
      expect(policy(user).destroy?).to be true
    end

    it "allows manage_moderators" do
      expect(policy(user).manage_moderators?).to be true
    end
  end

  describe "Scope" do
    let(:user) { create(:user) }
    let!(:space1) { create(:space, name: "Space 1") }
    let!(:space2) { create(:space, name: "Space 2") }

    it "returns all spaces for all users" do
      scope = described_class::Scope.new(user, Space).resolve
      expect(scope).to include(space1, space2)
    end

    it "returns all spaces even for visitors" do
      scope = described_class::Scope.new(nil, Space).resolve
      expect(scope).to include(space1, space2)
    end
  end
end
