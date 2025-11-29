# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Spaces" do
  describe "GET /spaces" do
    it "returns http success" do
      get spaces_path
      expect(response).to have_http_status(:success)
    end

    it "displays spaces alphabetically" do
      create(:space, name: "Zebra")
      create(:space, name: "Apple")

      get spaces_path

      expect(response.body).to include("Apple")
      expect(response.body).to include("Zebra")
      expect(response.body.index("Apple")).to be < response.body.index("Zebra")
    end

    it "shows subscribed status for user's subscribed spaces" do
      user = create(:user)
      subscribed_space = create(:space, name: "Subscribed Space")
      create(:space, name: "Other Space")
      create(:space_subscription, user: user, space: subscribed_space)

      sign_in user
      get spaces_path

      expect(response.body).to include("badge-subscribed")
    end

    it "shows question counts" do
      space = create(:space)
      create_list(:question, 3, space: space)

      get spaces_path

      expect(response.body).to include("3 questions")
    end

    it "shows message when no spaces exist" do
      get spaces_path

      expect(response.body).to include("No spaces yet.")
    end
  end

  describe "GET /spaces/:id" do
    it "returns http success" do
      space = create(:space)

      get space_path(space)

      expect(response).to have_http_status(:success)
    end

    it "displays the space" do
      space = create(:space, description: "A great space")

      get space_path(space)

      expect(response.body).to include(space.name)
      expect(response.body).to include(space.description)
    end

    it "displays questions in the space" do
      space = create(:space)
      question = create(:question, space: space)

      get space_path(space)

      expect(response.body).to include(question.title)
      expect(response.body).to include(question.author.display_name)
    end

    it "shows message when no questions exist in space" do
      space = create(:space)

      get space_path(space)

      expect(response.body).to include("No questions in this space yet.")
    end

    it "shows subscribed status when user is subscribed" do
      user = create(:user)
      space = create(:space)
      create(:space_subscription, user: user, space: space)

      sign_in user
      get space_path(space)

      expect(response.body).to include("You are subscribed")
    end
  end
end
