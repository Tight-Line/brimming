# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tag do
  describe "validations" do
    subject { build(:tag) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(1).is_at_most(50) }

    describe "name uniqueness" do
      subject { create(:tag) }

      it { is_expected.to validate_uniqueness_of(:name).scoped_to(:space_id).case_insensitive }
    end

    it "validates name format" do
      tag = build(:tag, name: "valid-tag-123")
      expect(tag).to be_valid

      tag.name = "Invalid Tag!"
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include("can only contain lowercase letters, numbers, hyphens, and periods")
    end

    describe "slug uniqueness" do
      subject { create(:tag) }

      it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:space_id).case_insensitive }
    end

    it { is_expected.to validate_length_of(:description).is_at_most(500) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:space) }
    it { is_expected.to have_many(:question_tags).dependent(:destroy) }
    it { is_expected.to have_many(:questions).through(:question_tags) }
  end

  describe "slug generation" do
    it "generates a slug from the name" do
      tag = create(:tag, name: "ruby-on-rails")
      expect(tag.slug).to eq("ruby-on-rails")
    end

    it "does not regenerate slug on update" do
      tag = create(:tag, name: "original")
      original_slug = tag.slug
      tag.update!(description: "Updated description")
      expect(tag.slug).to eq(original_slug)
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      tag = create(:tag, name: "ruby")
      expect(tag.to_param).to eq(tag.slug)
    end
  end

  describe "#display_name" do
    it "returns the name" do
      tag = create(:tag, name: "ruby")
      expect(tag.display_name).to eq("ruby")
    end
  end

  describe "scopes" do
    describe ".alphabetical" do
      it "orders tags by name" do
        space = create(:space)
        zebra = create(:tag, space: space, name: "zebra")
        apple = create(:tag, space: space, name: "apple")
        mango = create(:tag, space: space, name: "mango")

        expect(space.tags.alphabetical).to eq([ apple, mango, zebra ])
      end
    end

    describe ".search" do
      it "finds tags by name prefix" do
        space = create(:space)
        ruby = create(:tag, space: space, name: "ruby")
        ruby_on_rails = create(:tag, space: space, name: "ruby-on-rails")
        create(:tag, space: space, name: "python")

        expect(space.tags.search("ruby")).to contain_exactly(ruby, ruby_on_rails)
      end

      it "is case insensitive" do
        space = create(:space)
        ruby = create(:tag, space: space, name: "ruby")

        expect(space.tags.search("RUBY")).to contain_exactly(ruby)
      end

      it "returns none for blank query" do
        space = create(:space)
        create(:tag, space: space, name: "ruby")

        expect(space.tags.search("")).to be_empty
        expect(space.tags.search(nil)).to be_empty
      end
    end
  end

  describe "counter cache" do
    it "tracks questions_count" do
      tag = create(:tag)
      expect(tag.questions_count).to eq(0)

      question = create(:question, space: tag.space)
      QuestionTag.create!(question: question, tag: tag)

      expect(tag.reload.questions_count).to eq(1)
    end
  end
end
