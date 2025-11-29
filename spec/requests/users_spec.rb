# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users" do
  describe "GET /users/:username" do
    let(:user) { create(:user, username: "testuser", full_name: "Test User") }

    it "returns http success" do
      get user_path(user)
      expect(response).to have_http_status(:success)
    end

    it "uses username in the URL" do
      expect(user_path(user)).to eq("/users/testuser")
    end

    it "displays the user's username" do
      get user_path(user)
      expect(response.body).to include("testuser")
    end

    it "displays the user's full name when present" do
      get user_path(user)
      expect(response.body).to include("Test User")
    end

    it "displays the user's join date" do
      get user_path(user)
      expect(response.body).to include(user.created_at.strftime("%B %Y"))
    end

    it "displays admin badge for admin users" do
      admin = create(:user, :admin)
      get user_path(admin)
      expect(response.body).to include("Admin")
    end

    it "displays moderator badge for space moderators" do
      moderator = create(:user)
      space = create(:space)
      space.add_moderator(moderator)
      get user_path(moderator)
      expect(response.body).to include("Moderator")
    end

    it "displays karma score" do
      get user_path(user)
      expect(response.body).to include("Karma")
    end

    it "displays questions count" do
      create_list(:question, 3, user: user)
      get user_path(user)
      expect(response.body).to include("3")
      expect(response.body).to include("Questions")
    end

    it "displays answers count" do
      create_list(:answer, 2, user: user)
      get user_path(user)
      expect(response.body).to include("2")
      expect(response.body).to include("Answers")
    end

    it "displays solved answers count" do
      create(:answer, user: user, is_correct: true)
      create(:answer, user: user, is_correct: false)
      get user_path(user)
      expect(response.body).to include("1")
      expect(response.body).to include("Solved")
    end

    it "displays comments count" do
      question = create(:question)
      create_list(:comment, 4, user: user, commentable: question)
      get user_path(user)
      expect(response.body).to include("4")
      expect(response.body).to include("Comments")
    end

    it "displays subscribed spaces" do
      space = create(:space, name: "Ruby on Rails")
      create(:space_subscription, user: user, space: space)
      get user_path(user)
      expect(response.body).to include("Ruby on Rails")
      expect(response.body).to include("Subscribed Spaces")
    end

    it "displays recent questions" do
      question = create(:question, user: user, title: "How do I test Rails apps?")
      get user_path(user)
      expect(response.body).to include("How do I test Rails apps?")
      expect(response.body).to include("Recent Questions")
    end

    it "displays recent answers" do
      question = create(:question, title: "Testing question title")
      create(:answer, user: user, question: question)
      get user_path(user)
      expect(response.body).to include("Testing question title")
      expect(response.body).to include("Recent Answers")
    end

    it "shows empty state when no activity" do
      get user_path(user)
      expect(response.body).to include("No activity yet")
    end

    it "shows no subscriptions message when user has none" do
      get user_path(user)
      expect(response.body).to include("No subscriptions yet")
    end
  end
end
