# frozen_string_literal: true

require "rails_helper"

RSpec.describe Space do
  describe "validations" do
    subject { build(:space) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(100) }

    it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }

    it "requires slug to be present (generated from name if blank)" do
      space = build(:space, name: nil, slug: nil)
      expect(space).not_to be_valid
      expect(space.errors[:name]).to include("can't be blank")
    end
    it { is_expected.to allow_value("valid-slug-123").for(:slug) }
    it { is_expected.not_to allow_value("Invalid Slug").for(:slug) }
    it { is_expected.not_to allow_value("slug_with_underscore").for(:slug) }

    it { is_expected.to validate_length_of(:description).is_at_most(1000) }
  end

  describe "associations" do
    it { is_expected.to have_many(:questions).dependent(:destroy) }
    it { is_expected.to have_many(:space_moderators).dependent(:destroy) }
    it { is_expected.to have_many(:moderators).through(:space_moderators).source(:user) }
    it { is_expected.to have_many(:space_publishers).dependent(:destroy) }
    it { is_expected.to have_many(:publishers).through(:space_publishers).source(:user) }
    it { is_expected.to have_many(:space_subscriptions).dependent(:destroy) }
    it { is_expected.to have_many(:subscribers).through(:space_subscriptions).source(:user) }
    it { is_expected.to have_many(:article_spaces).dependent(:destroy) }
    it { is_expected.to have_many(:articles).through(:article_spaces) }
  end

  describe "callbacks" do
    describe "before_validation :generate_slug" do
      it "generates slug from name when slug is blank" do
        space = build(:space, name: "Ruby on Rails", slug: nil)
        space.valid?
        expect(space.slug).to eq("ruby-on-rails")
      end

      it "does not overwrite existing slug" do
        space = build(:space, name: "Ruby on Rails", slug: "custom-slug")
        space.valid?
        expect(space.slug).to eq("custom-slug")
      end

      it "handles special characters in name" do
        space = build(:space, name: "C++ & Python!", slug: nil)
        space.valid?
        expect(space.slug).to eq("c-python")
      end
    end
  end

  describe "scopes" do
    describe ".alphabetical" do
      it "orders spaces by name" do
        space_z = create(:space, name: "Zebra")
        space_a = create(:space, name: "Apple")
        space_m = create(:space, name: "Mango")

        expect(described_class.alphabetical).to eq([ space_a, space_m, space_z ])
      end
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      space = build(:space, slug: "my-space")
      expect(space.to_param).to eq("my-space")
    end
  end

  describe "#questions_count" do
    it "returns the count of questions in the space" do
      space = create(:space)
      create_list(:question, 4, space: space)
      expect(space.questions_count).to eq(4)
    end
  end

  describe "#add_moderator" do
    let(:space) { create(:space) }
    let(:user) { create(:user) }

    it "adds a user as moderator" do
      space.add_moderator(user)
      expect(space.moderators).to include(user)
    end

    it "does not duplicate moderators" do
      space.add_moderator(user)
      space.add_moderator(user)
      expect(space.moderators.count).to eq(1)
    end
  end

  describe "#remove_moderator" do
    let(:space) { create(:space) }
    let(:user) { create(:user) }

    it "removes a user as moderator" do
      space.add_moderator(user)
      space.remove_moderator(user)
      expect(space.moderators).not_to include(user)
    end
  end

  describe "#moderator?" do
    let(:space) { create(:space) }
    let(:user) { create(:user) }

    it "returns true if user is a moderator" do
      space.add_moderator(user)
      expect(space.moderator?(user)).to be true
    end

    it "returns false if user is not a moderator" do
      expect(space.moderator?(user)).to be false
    end
  end

  describe "#add_publisher" do
    let(:space) { create(:space) }
    let(:user) { create(:user) }

    it "adds a user as publisher" do
      space.add_publisher(user)
      expect(space.publishers).to include(user)
    end

    it "does not duplicate publishers" do
      space.add_publisher(user)
      space.add_publisher(user)
      expect(space.publishers.count).to eq(1)
    end
  end

  describe "#remove_publisher" do
    let(:space) { create(:space) }
    let(:user) { create(:user) }

    it "removes a user as publisher" do
      space.add_publisher(user)
      space.remove_publisher(user)
      expect(space.publishers).not_to include(user)
    end
  end

  describe "#publisher?" do
    let(:space) { create(:space) }
    let(:user) { create(:user) }

    it "returns true if user is a publisher" do
      space.add_publisher(user)
      expect(space.publisher?(user)).to be true
    end

    it "returns false if user is not a publisher" do
      expect(space.publisher?(user)).to be false
    end
  end

  describe "#effective_rag_chunk_limit" do
    let(:space) { create(:space) }

    context "when space has no override" do
      it "returns the global default" do
        expect(space.effective_rag_chunk_limit).to eq(SearchSetting.rag_chunk_limit)
      end
    end

    context "when space has an override" do
      before { space.update!(rag_chunk_limit: 25) }

      it "returns the space-specific limit" do
        expect(space.effective_rag_chunk_limit).to eq(25)
      end
    end

    context "when space override is 0" do
      before { space.update!(rag_chunk_limit: 0) }

      it "falls back to global default (0 is not a valid chunk limit)" do
        expect(space.effective_rag_chunk_limit).to eq(SearchSetting.rag_chunk_limit)
      end
    end

    context "when global default is customized" do
      before { SearchSetting.rag_chunk_limit = 15 }

      it "returns the customized global default" do
        expect(space.effective_rag_chunk_limit).to eq(15)
      end
    end
  end

  describe "#effective_similar_questions_limit" do
    let(:space) { create(:space) }

    context "when space has no override" do
      it "returns the global default" do
        expect(space.effective_similar_questions_limit).to eq(SearchSetting.similar_questions_limit)
      end
    end

    context "when space has an override" do
      before { space.update!(similar_questions_limit: 5) }

      it "returns the space-specific limit" do
        expect(space.effective_similar_questions_limit).to eq(5)
      end
    end

    context "when space override is 0" do
      before { space.update!(similar_questions_limit: 0) }

      it "returns 0 to disable the feature" do
        expect(space.effective_similar_questions_limit).to eq(0)
      end
    end

    context "when global default is customized" do
      before { SearchSetting.similar_questions_limit = 7 }

      it "returns the customized global default" do
        expect(space.effective_similar_questions_limit).to eq(7)
      end
    end
  end
end
