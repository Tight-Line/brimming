# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tags" do
  let(:space) { create(:space) }
  let(:user) { create(:user) }
  let(:moderator) { create(:user) }
  let(:admin) { create(:user, :admin) }

  before do
    create(:space_moderator, user: moderator, space: space)
  end

  # Helper to build paths since routes are scope-based, not nested resources
  def tags_path(space)
    "/spaces/#{space.slug}/tags"
  end

  def tag_path(space, tag)
    "/spaces/#{space.slug}/tags/#{tag.slug}"
  end

  def search_tags_path(space)
    "/spaces/#{space.slug}/tags/search"
  end

  describe "GET /spaces/:space_slug/tags" do
    it "returns tags for the space" do
      create(:tag, space: space, name: "ruby")
      create(:tag, space: space, name: "python")

      get tags_path(space)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ruby")
      expect(response.body).to include("python")
    end

    it "does not include tags from other spaces" do
      other_space = create(:space)
      create(:tag, space: space, name: "ruby")
      create(:tag, space: other_space, name: "python")

      get tags_path(space)

      expect(response.body).to include("ruby")
      expect(response.body).not_to include("python")
    end
  end

  describe "GET /spaces/:space_slug/tags/:slug" do
    let(:tag) { create(:tag, space: space) }

    it "shows the tag and its questions" do
      question = create(:question, space: space, tags: [ tag ])

      get tag_path(space, tag)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(tag.name)
      expect(response.body).to include(question.title)
    end
  end

  describe "GET /spaces/:space_slug/tags/search" do
    it "returns matching tags as JSON" do
      create(:tag, space: space, name: "ruby")
      create(:tag, space: space, name: "ruby-on-rails")
      create(:tag, space: space, name: "python")

      get search_tags_path(space), params: { q: "ruby" }, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json.length).to eq(2)
      expect(json.map { |t| t["name"] }).to contain_exactly("ruby", "ruby-on-rails")
    end

    it "handles tags with nil description" do
      create(:tag, space: space, name: "no-desc", description: nil)

      get search_tags_path(space), params: { q: "no-desc" }, as: :json

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json.first["description"]).to be_nil
    end
  end

  describe "POST /spaces/:space_slug/tags" do
    context "when user is not signed in" do
      it "redirects to login" do
        post tags_path(space), params: { tag: { name: "new-tag" } }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is a regular user" do
      before { sign_in user }

      it "forbids tag creation" do
        post tags_path(space), params: { tag: { name: "new-tag" } }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "when user is a moderator" do
      before { sign_in moderator }

      it "creates a tag" do
        expect {
          post tags_path(space), params: { tag: { name: "new-tag", description: "A new tag" } }
        }.to change(Tag, :count).by(1)

        expect(response).to redirect_to(tags_path(space))
        expect(Tag.last.name).to eq("new-tag")
      end

      it "returns tag as JSON on success" do
        post tags_path(space), params: { tag: { name: "json-tag", description: "A JSON tag" } }, as: :json

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["name"]).to eq("json-tag")
        expect(json["slug"]).to eq("json-tag")
        expect(json["description"]).to eq("A JSON tag")
        expect(json["questions_count"]).to eq(0)
        expect(json["id"]).to be_present
      end

      it "returns errors as JSON for invalid tag" do
        post tags_path(space), params: { tag: { name: "" } }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to be_present
      end
    end

    context "when user is an admin" do
      before { sign_in admin }

      it "creates a tag" do
        expect {
          post tags_path(space), params: { tag: { name: "admin-tag" } }
        }.to change(Tag, :count).by(1)
      end
    end
  end

  describe "DELETE /spaces/:space_slug/tags/:slug" do
    let!(:tag) { create(:tag, space: space) }

    context "when user is not signed in" do
      it "redirects to login" do
        delete tag_path(space, tag)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is a regular user" do
      before { sign_in user }

      it "forbids tag deletion" do
        delete tag_path(space, tag)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "when user is a moderator" do
      before { sign_in moderator }

      it "deletes the tag" do
        expect {
          delete tag_path(space, tag)
        }.to change(Tag, :count).by(-1)

        expect(response).to redirect_to(tags_path(space))
      end
    end

    context "when user is an admin" do
      before { sign_in admin }

      it "deletes the tag" do
        expect {
          delete tag_path(space, tag)
        }.to change(Tag, :count).by(-1)
      end
    end
  end
end
