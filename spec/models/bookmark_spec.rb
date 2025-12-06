# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bookmark do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:bookmarkable) }
  end

  describe "validations" do
    subject { create(:bookmark) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:bookmarkable_type, :bookmarkable_id).with_message("has already bookmarked this item") }
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let(:question) { create(:question) }
    let(:answer) { create(:answer) }
    let(:comment) { create(:comment) }
    let(:article) { create(:article) }

    before do
      create(:bookmark, user: user, bookmarkable: question, created_at: 1.day.ago)
      create(:bookmark, user: user, bookmarkable: answer, created_at: 2.days.ago)
      create(:bookmark, user: user, bookmarkable: comment, created_at: 3.days.ago)
      create(:bookmark, user: user, bookmarkable: article, created_at: 4.days.ago)
    end

    describe ".questions" do
      it "returns only question bookmarks" do
        expect(described_class.questions.count).to eq(1)
        expect(described_class.questions.first.bookmarkable).to eq(question)
      end
    end

    describe ".answers" do
      it "returns only answer bookmarks" do
        expect(described_class.answers.count).to eq(1)
        expect(described_class.answers.first.bookmarkable).to eq(answer)
      end
    end

    describe ".comments" do
      it "returns only comment bookmarks" do
        expect(described_class.comments.count).to eq(1)
        expect(described_class.comments.first.bookmarkable).to eq(comment)
      end
    end

    describe ".articles" do
      it "returns only article bookmarks" do
        expect(described_class.articles.count).to eq(1)
        expect(described_class.articles.first.bookmarkable).to eq(article)
      end
    end

    describe ".recent" do
      it "orders by created_at descending" do
        bookmarks = described_class.recent
        expect(bookmarks.first.bookmarkable).to eq(question)
        expect(bookmarks.last.bookmarkable).to eq(article)
      end
    end
  end

  describe "uniqueness" do
    let(:user) { create(:user) }
    let(:question) { create(:question) }

    it "allows one bookmark per user per item" do
      create(:bookmark, user: user, bookmarkable: question)
      duplicate = build(:bookmark, user: user, bookmarkable: question)
      expect(duplicate).not_to be_valid
    end

    it "allows same user to bookmark different items" do
      other_question = create(:question)
      create(:bookmark, user: user, bookmarkable: question)
      second_bookmark = build(:bookmark, user: user, bookmarkable: other_question)
      expect(second_bookmark).to be_valid
    end

    it "allows different users to bookmark the same item" do
      other_user = create(:user)
      create(:bookmark, user: user, bookmarkable: question)
      other_bookmark = build(:bookmark, user: other_user, bookmarkable: question)
      expect(other_bookmark).to be_valid
    end
  end

  describe "constants" do
    it "defines BOOKMARKABLE_TYPES" do
      expect(described_class::BOOKMARKABLE_TYPES).to eq(%w[Question Answer Comment Article])
    end
  end
end
