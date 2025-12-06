# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookmarkPolicy do
  let(:owner) { create(:user) }
  let(:question) { create(:question) }
  let(:bookmark) { create(:bookmark, user: owner, bookmarkable: question) }

  def policy(user)
    described_class.new(user, bookmark)
  end

  describe "for visitors (no user)" do
    let(:user) { nil }

    it "denies index" do
      expect(policy(user).index?).to be_falsey
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
  end

  describe "for regular users (not owner)" do
    let(:user) { create(:user) }

    it "allows index" do
      expect(policy(user).index?).to be true
    end

    it "allows create" do
      expect(policy(user).create?).to be true
    end

    it "denies update on other user's bookmark" do
      expect(policy(user).update?).to be false
    end

    it "denies destroy on other user's bookmark" do
      expect(policy(user).destroy?).to be false
    end
  end

  describe "for the owner" do
    it "allows index" do
      expect(policy(owner).index?).to be true
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
  end

  describe "for admins" do
    let(:admin) { create(:user, :admin) }

    it "allows index" do
      expect(policy(admin).index?).to be true
    end

    it "allows create" do
      expect(policy(admin).create?).to be true
    end

    it "denies update on other user's bookmark (admins don't have special privileges)" do
      expect(policy(admin).update?).to be false
    end

    it "denies destroy on other user's bookmark (admins don't have special privileges)" do
      expect(policy(admin).destroy?).to be false
    end
  end

  describe "Scope" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:user_bookmark) { create(:bookmark, user: user, bookmarkable: question) }
    let!(:other_bookmark) { create(:bookmark, user: other_user, bookmarkable: create(:question)) }

    it "returns only user's own bookmarks" do
      scope = described_class::Scope.new(user, Bookmark).resolve
      expect(scope).to include(user_bookmark)
      expect(scope).not_to include(other_bookmark)
    end

    it "returns nothing for visitors" do
      scope = described_class::Scope.new(nil, Bookmark).resolve
      expect(scope).to be_empty
    end
  end
end
