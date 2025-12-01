# frozen_string_literal: true

require "rails_helper"

RSpec.describe Article do
  include ActiveSupport::Testing::TimeHelpers

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:last_editor).class_name("User").optional }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:chunks).dependent(:destroy) }
    it { is_expected.to have_many(:article_votes).dependent(:destroy) }

    it { is_expected.to have_many(:article_spaces).dependent(:destroy) }
    it { is_expected.to have_many(:spaces).through(:article_spaces) }

    it "has one attached original_file" do
      article = described_class.reflect_on_attachment(:original_file)
      expect(article).to be_present
    end
  end

  describe "validations" do
    subject { build(:article, :with_custom_slug) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_least(3).is_at_most(200) }
    it { is_expected.to validate_inclusion_of(:content_type).in_array(described_class::CONTENT_TYPES) }

    it "sets default content_type to markdown" do
      article = build(:article, content_type: nil)
      article.valid?
      expect(article.content_type).to eq("markdown")
    end

    describe "slug presence" do
      it "requires slug after validation (auto-generated if blank)" do
        article = build(:article, title: "Test Title", slug: nil)
        article.valid?
        expect(article.slug).to be_present
      end
    end

    describe "slug uniqueness" do
      it "validates uniqueness of slug" do
        create(:article, slug: "unique-slug")
        article = build(:article, slug: "unique-slug")
        expect(article).not_to be_valid
        expect(article.errors[:slug]).to include("has already been taken")
      end
    end

    describe "slug format" do
      it "allows lowercase letters, numbers, and hyphens" do
        article = build(:article, slug: "valid-slug-123")
        expect(article).to be_valid
      end

      it "rejects uppercase letters" do
        article = build(:article, slug: "Invalid-Slug")
        expect(article).not_to be_valid
        expect(article.errors[:slug]).to include("can only contain lowercase letters, numbers, and hyphens")
      end

      it "rejects spaces" do
        article = build(:article, slug: "invalid slug")
        expect(article).not_to be_valid
      end

      it "rejects special characters" do
        article = build(:article, slug: "invalid_slug!")
        expect(article).not_to be_valid
      end
    end
  end

  describe "callbacks" do
    describe "content type detection from file" do
      it "sets content_type to pdf for .pdf files" do
        article = build(:article, content_type: "markdown")
        article.original_file.attach(
          io: StringIO.new("fake pdf content"),
          filename: "document.pdf",
          content_type: "application/pdf"
        )
        article.valid?
        expect(article.content_type).to eq("pdf")
      end

      it "sets content_type to docx for .docx files" do
        article = build(:article, content_type: "markdown")
        article.original_file.attach(
          io: StringIO.new("fake docx content"),
          filename: "document.docx",
          content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        )
        article.valid?
        expect(article.content_type).to eq("docx")
      end

      it "sets content_type to xlsx for .xlsx files" do
        article = build(:article, content_type: "markdown")
        article.original_file.attach(
          io: StringIO.new("fake xlsx content"),
          filename: "spreadsheet.xlsx",
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
        article.valid?
        expect(article.content_type).to eq("xlsx")
      end

      it "sets content_type to html for .html files" do
        article = build(:article, content_type: "markdown")
        article.original_file.attach(
          io: StringIO.new("<html></html>"),
          filename: "page.html",
          content_type: "text/html"
        )
        article.valid?
        expect(article.content_type).to eq("html")
      end

      it "does not change content_type for unknown extensions" do
        article = build(:article, content_type: "markdown")
        article.original_file.attach(
          io: StringIO.new("some content"),
          filename: "file.unknown",
          content_type: "application/octet-stream"
        )
        article.valid?
        expect(article.content_type).to eq("markdown")
      end
    end

    describe "slug generation" do
      it "generates slug from title if blank" do
        article = build(:article, title: "My Great Article", slug: nil)
        article.valid?
        expect(article.slug).to eq("my-great-article")
      end

      it "does not overwrite existing slug" do
        article = build(:article, title: "My Article", slug: "custom-slug")
        article.valid?
        expect(article.slug).to eq("custom-slug")
      end

      it "handles special characters in title" do
        article = build(:article, title: "What's the Best Way?", slug: nil)
        article.valid?
        expect(article.slug).to eq("what-s-the-best-way")
      end

      it "handles multiple spaces and hyphens" do
        article = build(:article, title: "Too   Many   Spaces", slug: nil)
        article.valid?
        expect(article.slug).to eq("too-many-spaces")
      end

      it "removes leading and trailing hyphens" do
        article = build(:article, title: "  Leading Spaces  ", slug: nil)
        article.valid?
        expect(article.slug).to eq("leading-spaces")
      end

      it "ensures uniqueness by appending counter" do
        create(:article, slug: "my-article")
        article = build(:article, title: "My Article", slug: nil)
        article.valid?
        expect(article.slug).to eq("my-article-1")
      end

      it "increments counter for multiple duplicates" do
        create(:article, slug: "my-article")
        create(:article, slug: "my-article-1")
        article = build(:article, title: "My Article", slug: nil)
        article.valid?
        expect(article.slug).to eq("my-article-2")
      end

      it "does not generate slug when title is blank" do
        article = build(:article, title: nil, slug: nil)
        article.valid?
        expect(article.slug).to be_nil
      end
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only non-deleted articles" do
        active = create(:article)
        _deleted = create(:article, :deleted)

        expect(described_class.active).to contain_exactly(active)
      end
    end

    describe ".deleted" do
      it "returns only deleted articles" do
        _active = create(:article)
        deleted = create(:article, :deleted)

        expect(described_class.deleted).to contain_exactly(deleted)
      end
    end

    describe ".recent" do
      it "orders by created_at desc" do
        old = create(:article, created_at: 2.days.ago)
        new = create(:article, created_at: 1.day.ago)

        expect(described_class.recent).to eq([ new, old ])
      end
    end

    describe ".by_content_type" do
      it "filters by content type" do
        markdown = create(:article, content_type: "markdown")
        _html = create(:article, :html)

        expect(described_class.by_content_type("markdown")).to contain_exactly(markdown)
      end
    end

    describe ".orphaned" do
      it "returns active articles without spaces" do
        orphaned = create(:article)
        with_space = create(:article)
        create(:article_space, article: with_space)
        _deleted_orphan = create(:article, :deleted)

        expect(described_class.orphaned).to contain_exactly(orphaned)
      end
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      article = build(:article, slug: "my-slug")
      expect(article.to_param).to eq("my-slug")
    end
  end

  describe "#deleted?" do
    it "returns true when deleted_at is present" do
      article = build(:article, :deleted)
      expect(article.deleted?).to be true
    end

    it "returns false when deleted_at is nil" do
      article = build(:article)
      expect(article.deleted?).to be false
    end
  end

  describe "#soft_delete!" do
    it "sets deleted_at to current time" do
      article = create(:article)
      freeze_time do
        article.soft_delete!
        expect(article.deleted_at).to eq(Time.current)
      end
    end
  end

  describe "#restore!" do
    it "clears deleted_at" do
      article = create(:article, :deleted)
      article.restore!
      expect(article.deleted_at).to be_nil
    end
  end

  describe "#orphaned?" do
    it "returns true when article has no spaces" do
      article = build(:article)
      expect(article.orphaned?).to be true
    end

    it "returns false when article has spaces" do
      article = create(:article)
      create(:article_space, article: article)
      expect(article.orphaned?).to be false
    end
  end

  describe "#text_content?" do
    it "returns true for markdown" do
      expect(build(:article, content_type: "markdown").text_content?).to be true
    end

    it "returns true for html" do
      expect(build(:article, content_type: "html").text_content?).to be true
    end

    it "returns true for txt" do
      expect(build(:article, content_type: "txt").text_content?).to be true
    end

    it "returns false for pdf" do
      expect(build(:article, content_type: "pdf").text_content?).to be false
    end

    it "returns false for docx" do
      expect(build(:article, content_type: "docx").text_content?).to be false
    end

    it "returns false for xlsx" do
      expect(build(:article, content_type: "xlsx").text_content?).to be false
    end
  end

  describe "#binary_content?" do
    it "returns true for pdf" do
      expect(build(:article, content_type: "pdf").binary_content?).to be true
    end

    it "returns true for docx" do
      expect(build(:article, content_type: "docx").binary_content?).to be true
    end

    it "returns true for xlsx" do
      expect(build(:article, content_type: "xlsx").binary_content?).to be true
    end

    it "returns false for markdown" do
      expect(build(:article, content_type: "markdown").binary_content?).to be false
    end

    it "returns false for html" do
      expect(build(:article, content_type: "html").binary_content?).to be false
    end

    it "returns false for txt" do
      expect(build(:article, content_type: "txt").binary_content?).to be false
    end
  end

  describe "#mark_edited!" do
    it "sets last_editor and edited_at" do
      article = create(:article)
      editor = create(:user)

      freeze_time do
        article.mark_edited!(editor)
        expect(article.last_editor).to eq(editor)
        expect(article.edited_at).to eq(Time.current)
      end
    end
  end

  describe "#owned_by?" do
    let(:owner) { create(:user) }
    let(:other_user) { create(:user) }
    let(:article) { create(:article, user: owner) }

    it "returns true for the owner" do
      expect(article.owned_by?(owner)).to be true
    end

    it "returns false for a different user" do
      expect(article.owned_by?(other_user)).to be false
    end

    it "returns false for nil" do
      expect(article.owned_by?(nil)).to be false
    end
  end

  describe "#display_content_type" do
    it "returns 'Markdown' for markdown" do
      expect(build(:article, content_type: "markdown").display_content_type).to eq("Markdown")
    end

    it "returns 'HTML' for html" do
      expect(build(:article, content_type: "html").display_content_type).to eq("HTML")
    end

    it "returns 'PDF' for pdf" do
      expect(build(:article, content_type: "pdf").display_content_type).to eq("PDF")
    end

    it "returns 'Word Document' for docx" do
      expect(build(:article, content_type: "docx").display_content_type).to eq("Word Document")
    end

    it "returns 'Excel Spreadsheet' for xlsx" do
      expect(build(:article, content_type: "xlsx").display_content_type).to eq("Excel Spreadsheet")
    end

    it "returns 'Plain Text' for txt" do
      expect(build(:article, content_type: "txt").display_content_type).to eq("Plain Text")
    end
  end

  describe "#increment_views!" do
    it "increments the views_count by 1" do
      article = create(:article, views_count: 5)
      article.increment_views!
      expect(article.reload.views_count).to eq(6)
    end
  end

  describe "voting methods" do
    let(:article) { create(:article) }
    let(:voter) { create(:user) }

    describe "#upvote_by" do
      it "creates an upvote and increments vote_score" do
        expect { article.upvote_by(voter) }.to change { article.article_votes.count }.by(1)
        expect(article.reload.vote_score).to eq(1)
      end

      it "does not create duplicate votes" do
        article.upvote_by(voter)
        expect { article.upvote_by(voter) }.not_to change { article.article_votes.count }
        expect(article.reload.vote_score).to eq(1)
      end
    end

    describe "#remove_vote_by" do
      it "removes the vote and decrements vote_score" do
        article.upvote_by(voter)
        expect(article.reload.vote_score).to eq(1)

        article.remove_vote_by(voter)
        expect(article.reload.vote_score).to eq(0)
        expect(article.article_votes.count).to eq(0)
      end

      it "does nothing if user has not voted" do
        expect { article.remove_vote_by(voter) }.not_to change { article.vote_score }
      end
    end

    describe "#vote_by" do
      it "returns the vote for the given user" do
        article.upvote_by(voter)
        vote = article.vote_by(voter)
        expect(vote).to be_present
        expect(vote.user).to eq(voter)
      end

      it "returns nil if user has not voted" do
        expect(article.vote_by(voter)).to be_nil
      end
    end

    describe "#upvoted_by?" do
      it "returns true if user has upvoted" do
        article.upvote_by(voter)
        expect(article.upvoted_by?(voter)).to be true
      end

      it "returns false if user has not voted" do
        expect(article.upvoted_by?(voter)).to be false
      end
    end

    describe "#recalculate_vote_score!" do
      it "recalculates vote_score from actual votes" do
        voter1 = create(:user)
        voter2 = create(:user)

        article.upvote_by(voter1)
        article.upvote_by(voter2)

        # Manually corrupt the score
        article.update_column(:vote_score, 99)
        expect(article.vote_score).to eq(99)

        article.recalculate_vote_score!
        expect(article.vote_score).to eq(2)
      end
    end
  end
end
