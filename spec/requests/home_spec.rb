# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home" do
  describe "GET /" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "displays recent questions" do
      category = create(:category)
      user = create(:user)
      question = create(:question, user: user, category: category)

      get root_path

      expect(response.body).to include(question.title)
      expect(response.body).to include(category.name)
      expect(response.body).to include(user.username)
    end

    it "displays categories" do
      category = create(:category, name: "Ruby")

      get root_path

      expect(response.body).to include("Ruby")
    end

    it "shows subscribed status for user's subscribed categories" do
      user = create(:user)
      subscribed_category = create(:category, name: "Subscribed Category")
      unsubscribed_category = create(:category, name: "Unsubscribed Category")
      create(:category_subscription, user: user, category: subscribed_category)

      get root_path

      expect(response.body).to include("Subscribed Category")
      expect(response.body).to include("badge-subscribed")
      expect(response.body).to include("Unsubscribed Category")
    end

    it "limits recent questions to 10" do
      category = create(:category)
      user = create(:user)
      create_list(:question, 15, user: user, category: category)

      get root_path

      # The page should show only 10 questions
      expect(response.body.scan(/<li>/).count).to be <= 12 # 10 questions + categories
    end

    it "shows message when no questions exist" do
      get root_path

      expect(response.body).to include("No questions yet.")
    end
  end
end
