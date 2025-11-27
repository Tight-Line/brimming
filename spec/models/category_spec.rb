# frozen_string_literal: true

require "rails_helper"

RSpec.describe Category do
  describe "validations" do
    subject { build(:category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(100) }

    it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }

    it "requires slug to be present (generated from name if blank)" do
      category = build(:category, name: nil, slug: nil)
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("can't be blank")
    end
    it { is_expected.to allow_value("valid-slug-123").for(:slug) }
    it { is_expected.not_to allow_value("Invalid Slug").for(:slug) }
    it { is_expected.not_to allow_value("slug_with_underscore").for(:slug) }

    it { is_expected.to validate_length_of(:description).is_at_most(1000) }
  end

  describe "associations" do
    it { is_expected.to have_many(:questions).dependent(:destroy) }
    it { is_expected.to have_many(:category_moderators).dependent(:destroy) }
    it { is_expected.to have_many(:moderators).through(:category_moderators).source(:user) }
  end

  describe "callbacks" do
    describe "before_validation :generate_slug" do
      it "generates slug from name when slug is blank" do
        category = build(:category, name: "Ruby on Rails", slug: nil)
        category.valid?
        expect(category.slug).to eq("ruby-on-rails")
      end

      it "does not overwrite existing slug" do
        category = build(:category, name: "Ruby on Rails", slug: "custom-slug")
        category.valid?
        expect(category.slug).to eq("custom-slug")
      end

      it "handles special characters in name" do
        category = build(:category, name: "C++ & Python!", slug: nil)
        category.valid?
        expect(category.slug).to eq("c-python")
      end
    end
  end

  describe "scopes" do
    describe ".alphabetical" do
      it "orders categories by name" do
        category_z = create(:category, name: "Zebra")
        category_a = create(:category, name: "Apple")
        category_m = create(:category, name: "Mango")

        expect(described_class.alphabetical).to eq([ category_a, category_m, category_z ])
      end
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      category = build(:category, slug: "my-category")
      expect(category.to_param).to eq("my-category")
    end
  end

  describe "#questions_count" do
    it "returns the count of questions in the category" do
      category = create(:category)
      create_list(:question, 4, category: category)
      expect(category.questions_count).to eq(4)
    end
  end

  describe "#add_moderator" do
    let(:category) { create(:category) }
    let(:user) { create(:user) }

    it "adds a user as moderator" do
      category.add_moderator(user)
      expect(category.moderators).to include(user)
    end

    it "does not duplicate moderators" do
      category.add_moderator(user)
      category.add_moderator(user)
      expect(category.moderators.count).to eq(1)
    end
  end

  describe "#remove_moderator" do
    let(:category) { create(:category) }
    let(:user) { create(:user) }

    it "removes a user as moderator" do
      category.add_moderator(user)
      category.remove_moderator(user)
      expect(category.moderators).not_to include(user)
    end
  end
end
