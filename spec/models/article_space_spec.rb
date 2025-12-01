# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArticleSpace do
  describe "associations" do
    it { is_expected.to belong_to(:article) }
    it { is_expected.to belong_to(:space) }
  end

  describe "validations" do
    it "validates uniqueness of article within space" do
      article = create(:article)
      space = create(:space)
      create(:article_space, article: article, space: space)

      duplicate = build(:article_space, article: article, space: space)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:article_id]).to include("is already associated with this space")
    end

    it "allows same article in different spaces" do
      article = create(:article)
      space1 = create(:space)
      space2 = create(:space)
      create(:article_space, article: article, space: space1)

      article_space2 = build(:article_space, article: article, space: space2)
      expect(article_space2).to be_valid
    end

    it "allows different articles in the same space" do
      article1 = create(:article)
      article2 = create(:article)
      space = create(:space)
      create(:article_space, article: article1, space: space)

      article_space2 = build(:article_space, article: article2, space: space)
      expect(article_space2).to be_valid
    end
  end
end
