# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Categories" do
  describe "GET /categories" do
    it "returns http success" do
      get categories_path
      expect(response).to have_http_status(:success)
    end

    it "displays categories alphabetically" do
      create(:category, name: "Zebra")
      create(:category, name: "Apple")

      get categories_path

      expect(response.body).to include("Apple")
      expect(response.body).to include("Zebra")
      expect(response.body.index("Apple")).to be < response.body.index("Zebra")
    end

    it "shows subscribed status for user's subscribed categories" do
      user = create(:user)
      subscribed_category = create(:category, name: "Subscribed Category")
      create(:category, name: "Other Category")
      create(:category_subscription, user: user, category: subscribed_category)

      sign_in user
      get categories_path

      expect(response.body).to include("badge-subscribed")
    end

    it "shows question counts" do
      category = create(:category)
      create_list(:question, 3, category: category)

      get categories_path

      expect(response.body).to include("3 questions")
    end

    it "shows message when no categories exist" do
      get categories_path

      expect(response.body).to include("No categories yet.")
    end
  end

  describe "GET /categories/:id" do
    it "returns http success" do
      category = create(:category)

      get category_path(category)

      expect(response).to have_http_status(:success)
    end

    it "displays the category" do
      category = create(:category, description: "A great category")

      get category_path(category)

      expect(response.body).to include(category.name)
      expect(response.body).to include(category.description)
    end

    it "displays questions in the category" do
      category = create(:category)
      question = create(:question, category: category)

      get category_path(category)

      expect(response.body).to include(question.title)
      expect(response.body).to include(question.author.display_name)
    end

    it "shows message when no questions exist in category" do
      category = create(:category)

      get category_path(category)

      expect(response.body).to include("No questions in this category yet.")
    end

    it "shows subscribed status when user is subscribed" do
      user = create(:user)
      category = create(:category)
      create(:category_subscription, user: user, category: category)

      sign_in user
      get category_path(category)

      expect(response.body).to include("You are subscribed")
    end
  end
end
