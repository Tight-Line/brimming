# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home" do
  describe "GET /" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "displays recent questions" do
      space = create(:space)
      user = create(:user)
      question = create(:question, user: user, space: space)

      get root_path

      expect(response.body).to include(question.title)
      expect(response.body).to include(space.name)
      expect(response.body).to include(user.username)
    end

    it "displays spaces" do
      space = create(:space, name: "Ruby")

      get root_path

      expect(response.body).to include("Ruby")
    end

    it "shows subscribed status for user's subscribed spaces" do
      user = create(:user)
      subscribed_space = create(:space, name: "Subscribed Space")
      unsubscribed_space = create(:space, name: "Unsubscribed Space")
      create(:space_subscription, user: user, space: subscribed_space)

      sign_in user
      get root_path

      # Check that subscribed space has the star icon indicator
      doc = Nokogiri::HTML(response.body)
      subscribed_item = doc.at_css(".space-name:contains('Subscribed Space')")
      expect(subscribed_item).to be_present
      expect(subscribed_item.at_css(".subscribed-icon")).to be_present

      # Check that unsubscribed space does NOT have the star icon
      unsubscribed_item = doc.at_css(".space-name:contains('Unsubscribed Space')")
      expect(unsubscribed_item).to be_present
      expect(unsubscribed_item.at_css(".subscribed-icon")).to be_nil
    end

    it "limits recent questions to 10" do
      space = create(:space)
      user = create(:user)
      create_list(:question, 15, user: user, space: space)

      get root_path

      # Count question items specifically using the question-item class
      expect(response.body.scan(/class="question-item"/).count).to eq(10)
    end

    it "shows message when no questions exist" do
      get root_path

      expect(response.body).to include("No questions yet.")
    end
  end
end
