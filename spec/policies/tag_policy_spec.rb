# frozen_string_literal: true

require "rails_helper"

RSpec.describe TagPolicy do
  let(:space) { create(:space) }
  let(:tag) { create(:tag, space: space) }

  def policy(user)
    described_class.new(user, tag)
  end

  describe "for visitors (no user)" do
    let(:user) { nil }

    it "allows index" do
      expect(policy(user).index?).to be true
    end

    it "allows show" do
      expect(policy(user).show?).to be true
    end

    it "allows search" do
      expect(policy(user).search?).to be true
    end

    it "denies create" do
      expect(policy(user).create?).to be false
    end

    it "denies destroy" do
      expect(policy(user).destroy?).to be false
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

    it "allows search" do
      expect(policy(user).search?).to be true
    end

    it "denies create" do
      expect(policy(user).create?).to be false
    end

    it "denies destroy" do
      expect(policy(user).destroy?).to be false
    end
  end

  describe "for space moderators" do
    let(:moderator) { create(:user) }

    before do
      create(:space_moderator, user: moderator, space: space)
    end

    it "allows index" do
      expect(policy(moderator).index?).to be true
    end

    it "allows show" do
      expect(policy(moderator).show?).to be true
    end

    it "allows search" do
      expect(policy(moderator).search?).to be true
    end

    it "allows create" do
      expect(policy(moderator).create?).to be true
    end

    it "allows destroy" do
      expect(policy(moderator).destroy?).to be true
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

    it "allows search" do
      expect(policy(admin).search?).to be true
    end

    it "allows create" do
      expect(policy(admin).create?).to be true
    end

    it "allows destroy" do
      expect(policy(admin).destroy?).to be true
    end

    it "allows update" do
      expect(policy(admin).update?).to be true
    end
  end

  describe "for visitors (update)" do
    let(:user) { nil }

    it "denies update" do
      expect(policy(user).update?).to be false
    end
  end

  describe "for regular users (update)" do
    let(:user) { create(:user) }

    it "denies update" do
      expect(policy(user).update?).to be false
    end
  end

  describe "for space moderators (update)" do
    let(:moderator) { create(:user) }

    before do
      create(:space_moderator, user: moderator, space: space)
    end

    it "allows update" do
      expect(policy(moderator).update?).to be true
    end
  end

  describe "Scope" do
    let(:user) { create(:user) }
    let!(:tag1) { create(:tag, space: space) }
    let!(:tag2) { create(:tag, space: space) }

    it "resolves to all tags" do
      scope = described_class::Scope.new(user, Tag.all).resolve
      expect(scope).to include(tag1, tag2)
    end
  end
end
