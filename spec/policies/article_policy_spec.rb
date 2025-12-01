# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArticlePolicy do
  let(:space) { create(:space) }
  let(:other_space) { create(:space) }
  let(:owner) { create(:user) }
  let(:article) { create(:article, user: owner) }

  def policy(user)
    described_class.new(user, article)
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

    it "denies manage_spaces" do
      expect(policy(user).manage_spaces?).to be_falsey
    end

    it "denies vote" do
      expect(policy(user).vote?).to be_falsey
    end
  end

  describe "for regular users (not owner, not publisher)" do
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

    it "denies hard_delete" do
      expect(policy(user).hard_delete?).to be false
    end

    it "denies manage_spaces" do
      expect(policy(user).manage_spaces?).to be false
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

    it "allows create (owner is also a user)" do
      # Owner can only create if they have publisher/moderator/admin privileges
      # Since owner is just a regular user here, create should be denied
      expect(policy(owner).create?).to be false
    end

    it "allows update" do
      expect(policy(owner).update?).to be true
    end

    it "allows destroy" do
      expect(policy(owner).destroy?).to be true
    end

    it "denies hard_delete (not moderator)" do
      expect(policy(owner).hard_delete?).to be false
    end

    it "allows manage_spaces" do
      expect(policy(owner).manage_spaces?).to be true
    end
  end

  describe "for space publishers" do
    let(:publisher) { create(:user) }

    before do
      space.add_publisher(publisher)
      create(:article_space, article: article, space: space)
    end

    it "allows create" do
      expect(policy(publisher).create?).to be true
    end

    it "allows update" do
      expect(policy(publisher).update?).to be true
    end

    it "allows destroy" do
      expect(policy(publisher).destroy?).to be true
    end

    it "denies hard_delete (not moderator)" do
      expect(policy(publisher).hard_delete?).to be false
    end

    it "allows manage_spaces" do
      expect(policy(publisher).manage_spaces?).to be true
    end

    context "when publisher is not for article's space" do
      let(:publisher_other_space) { create(:user) }

      before do
        other_space.add_publisher(publisher_other_space)
      end

      it "allows create (is a publisher in some space)" do
        expect(policy(publisher_other_space).create?).to be true
      end

      it "denies update (not publisher for article's space)" do
        expect(policy(publisher_other_space).update?).to be false
      end

      it "denies destroy (not publisher for article's space)" do
        expect(policy(publisher_other_space).destroy?).to be false
      end

      it "denies manage_spaces (not publisher for article's space)" do
        expect(policy(publisher_other_space).manage_spaces?).to be false
      end
    end
  end

  describe "for space moderators" do
    let(:moderator) { create(:user) }

    before do
      space.add_moderator(moderator)
      create(:article_space, article: article, space: space)
    end

    it "allows create" do
      expect(policy(moderator).create?).to be true
    end

    it "allows update (moderators can publish)" do
      expect(policy(moderator).update?).to be true
    end

    it "allows destroy" do
      expect(policy(moderator).destroy?).to be true
    end

    it "allows hard_delete" do
      expect(policy(moderator).hard_delete?).to be true
    end

    it "allows manage_spaces" do
      expect(policy(moderator).manage_spaces?).to be true
    end

    context "when moderator is not for article's space" do
      let(:moderator_other_space) { create(:user) }

      before do
        other_space.add_moderator(moderator_other_space)
      end

      it "allows create (is a moderator in some space)" do
        expect(policy(moderator_other_space).create?).to be true
      end

      it "denies update" do
        expect(policy(moderator_other_space).update?).to be false
      end

      it "denies hard_delete" do
        expect(policy(moderator_other_space).hard_delete?).to be false
      end
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

    it "allows update" do
      expect(policy(admin).update?).to be true
    end

    it "allows destroy" do
      expect(policy(admin).destroy?).to be true
    end

    it "allows hard_delete" do
      expect(policy(admin).hard_delete?).to be true
    end

    it "allows manage_spaces" do
      expect(policy(admin).manage_spaces?).to be true
    end
  end

  describe "for orphaned articles (no spaces)" do
    let(:orphaned_article) { create(:article, user: owner) }

    def orphan_policy(user)
      described_class.new(user, orphaned_article)
    end

    context "for regular user" do
      let(:user) { create(:user) }

      it "denies update" do
        expect(orphan_policy(user).update?).to be false
      end

      it "denies hard_delete" do
        expect(orphan_policy(user).hard_delete?).to be false
      end
    end

    context "for publisher in a different space" do
      let(:publisher) { create(:user) }

      before { space.add_publisher(publisher) }

      it "denies update (no matching space)" do
        expect(orphan_policy(publisher).update?).to be false
      end
    end

    context "for owner" do
      it "allows update" do
        expect(orphan_policy(owner).update?).to be true
      end

      it "allows destroy" do
        expect(orphan_policy(owner).destroy?).to be true
      end
    end

    context "for admin" do
      let(:admin) { create(:user, :admin) }

      it "allows update" do
        expect(orphan_policy(admin).update?).to be true
      end

      it "allows hard_delete" do
        expect(orphan_policy(admin).hard_delete?).to be true
      end
    end
  end

  describe "Scope" do
    let(:user) { create(:user) }
    let!(:active_article) { create(:article) }
    let!(:deleted_article) { create(:article, deleted_at: Time.current) }

    it "returns only active (non-deleted) articles" do
      scope = described_class::Scope.new(user, Article).resolve
      expect(scope).to include(active_article)
      expect(scope).not_to include(deleted_article)
    end

    it "works for visitors" do
      scope = described_class::Scope.new(nil, Article).resolve
      expect(scope).to include(active_article)
      expect(scope).not_to include(deleted_article)
    end
  end
end
