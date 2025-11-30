# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Search" do
  let(:space) { create(:space) }
  let(:user) { create(:user) }

  describe "GET /search" do
    it "renders the search page" do
      get search_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Search")
    end

    it "searches with a query" do
      question = create(:question, space: space, user: user, title: "Test Question about Ruby programming")

      get search_path, params: { q: "Ruby programming" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Test Question")
      expect(response.body).to include("1 result")
    end

    it "filters by space" do
      other_space = create(:space)
      question_in_space = create(:question, space: space, title: "Question in target space")
      create(:question, space: other_space, title: "Question in other space")

      get search_path, params: { q: "", space: space.slug }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(question_in_space.title)
    end

    it "filters by user" do
      other_user = create(:user)
      question_by_user = create(:question, user: user, title: "Question by target user")
      create(:question, user: other_user, title: "Question by other user")

      get search_path, params: { q: "", user: user.username }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(question_by_user.title)
    end

    it "filters by tags" do
      tag = create(:tag, space: space, name: "ruby")
      question_with_tag = create(:question, space: space, title: "Tagged question", tags: [ tag ])
      create(:question, space: space, title: "Untagged question")

      get search_path, params: { q: "", space: space.slug, tags: [ "ruby" ] }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(question_with_tag.title)
    end

    it "supports different sort orders" do
      old_question = create(:question, space: space, title: "Old question", created_at: 1.week.ago)
      new_question = create(:question, space: space, title: "New question", created_at: 1.hour.ago)

      get search_path, params: { q: "", space: space.slug, sort: "newest" }

      expect(response).to have_http_status(:ok)
      # New question should appear first
      expect(response.body.index(new_question.title)).to be < response.body.index(old_question.title)
    end

    it "returns JSON when requested" do
      question = create(:question, space: space, user: user, title: "Test Question for JSON")

      get search_path, params: { q: "JSON" }, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["query"]).to eq("JSON")
      expect(json["results"].length).to eq(1)
      expect(json["results"].first["title"]).to eq("Test Question for JSON")
    end

    it "returns JSON with filters including space and user" do
      get search_path, params: { q: "test", space: space.slug, user: user.username }, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["filters"]["space"]).to eq(space.slug)
      expect(json["filters"]["user"]).to eq(user.username)
    end

    it "returns JSON with nil filters when no space or user specified" do
      get search_path, params: { q: "test" }, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["filters"]["space"]).to be_nil
      expect(json["filters"]["user"]).to be_nil
    end

    it "truncates long body excerpts" do
      long_body = "x" * 300
      create(:question, space: space, title: "Test question with long body", body: long_body)

      get search_path, params: { q: "", space: space.slug }, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["results"].first["excerpt"].length).to be <= 200
    end
  end

  describe "GET /search/suggestions" do
    it "returns question suggestions as JSON" do
      create(:question, space: space, title: "How to use Ruby?")

      get search_suggestions_path, params: { q: "ruby" }, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["questions"].length).to eq(1)
      expect(json["questions"].first["title"]).to eq("How to use Ruby?")
    end

    it "returns empty for blank query" do
      get search_suggestions_path, params: { q: "" }, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["questions"]).to be_empty
    end

    it "limits results to 5 suggestions" do
      10.times { |i| create(:question, space: space, title: "Ruby question #{i}") }

      get search_suggestions_path, params: { q: "Ruby" }, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["questions"].length).to be <= 5
    end
  end
end
