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

    it "shows admin actions for admins" do
      admin = create(:user, :admin)
      space = create(:space)

      sign_in admin
      get space_path(space)

      expect(response.body).to include("Edit")
      expect(response.body).to include("Moderators")
      expect(response.body).to include("Delete")
    end

    it "does not show admin actions for regular users" do
      user = create(:user)
      space = create(:space)

      sign_in user
      get space_path(space)

      expect(response.body).not_to include("admin-actions")
    end

    it "shows Moderators link for space moderators" do
      user = create(:user)
      space = create(:space)
      space.add_moderator(user)

      sign_in user
      get space_path(space)

      expect(response.body).to include("Moderators")
      expect(response.body).not_to include("Edit")
      expect(response.body).not_to include("Delete")
    end
  end

  describe "GET /spaces/new" do
    it "requires login" do
      get new_space_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects non-admins" do
      user = create(:user)
      sign_in user

      get new_space_path
      expect(response).to redirect_to(root_path)
    end

    it "shows form for admins" do
      admin = create(:user, :admin)
      sign_in admin

      get new_space_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Create Space")
    end
  end

  describe "POST /spaces" do
    it "requires login" do
      post spaces_path, params: { space: { name: "Test" } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not allow non-admins to create spaces" do
      user = create(:user)
      sign_in user

      post spaces_path, params: { space: { name: "Test" } }
      expect(response).to redirect_to(root_path)
    end

    it "allows admins to create spaces" do
      admin = create(:user, :admin)
      sign_in admin

      expect {
        post spaces_path, params: { space: { name: "New Space", description: "A new space" } }
      }.to change(Space, :count).by(1)

      expect(response).to redirect_to(space_path(Space.last))
    end

    it "re-renders form with errors for invalid data" do
      admin = create(:user, :admin)
      sign_in admin

      post spaces_path, params: { space: { name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /spaces/:id/edit" do
    it "requires login" do
      space = create(:space)
      get edit_space_path(space)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects non-admins" do
      user = create(:user)
      space = create(:space)
      sign_in user

      get edit_space_path(space)
      expect(response).to redirect_to(root_path)
    end

    it "shows form for admins" do
      admin = create(:user, :admin)
      space = create(:space)
      sign_in admin

      get edit_space_path(space)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Edit Space")
    end
  end

  describe "PATCH /spaces/:id" do
    it "requires login" do
      space = create(:space)
      patch space_path(space), params: { space: { name: "Updated" } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not allow non-admins to update spaces" do
      user = create(:user)
      space = create(:space)
      sign_in user

      patch space_path(space), params: { space: { name: "Updated" } }
      expect(response).to redirect_to(root_path)
    end

    it "allows admins to update spaces" do
      admin = create(:user, :admin)
      space = create(:space, name: "Original")
      sign_in admin

      patch space_path(space), params: { space: { name: "Updated" } }

      expect(space.reload.name).to eq("Updated")
      expect(response).to redirect_to(space_path(space))
    end

    it "re-renders form with errors for invalid data" do
      admin = create(:user, :admin)
      space = create(:space)
      sign_in admin

      patch space_path(space), params: { space: { name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /spaces/:id" do
    it "requires login" do
      space = create(:space)
      delete space_path(space)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not allow non-admins to delete spaces" do
      user = create(:user)
      space = create(:space)
      sign_in user

      delete space_path(space)
      expect(response).to redirect_to(root_path)
    end

    it "allows admins to delete empty spaces" do
      admin = create(:user, :admin)
      space = create(:space)
      sign_in admin

      expect {
        delete space_path(space)
      }.to change(Space, :count).by(-1)

      expect(response).to redirect_to(spaces_path)
    end

    it "prevents deletion of spaces with questions" do
      admin = create(:user, :admin)
      space = create(:space)
      create(:question, space: space)
      sign_in admin

      expect {
        delete space_path(space)
      }.not_to change(Space, :count)

      expect(response).to redirect_to(space_path(space))
      expect(flash[:alert]).to include("Cannot delete")
    end
  end

  describe "GET /spaces/:id/moderators" do
    it "requires login" do
      space = create(:space)
      get moderators_space_path(space)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects non-admins" do
      user = create(:user)
      space = create(:space)
      sign_in user

      get moderators_space_path(space)
      expect(response).to redirect_to(root_path)
    end

    it "shows moderator management page for admins" do
      admin = create(:user, :admin)
      space = create(:space)
      moderator = create(:user)
      space.add_moderator(moderator)
      sign_in admin

      get moderators_space_path(space)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Manage Moderators")
      expect(response.body).to include(moderator.display_name)
    end

    it "shows moderator management page for space moderators" do
      space = create(:space)
      moderator = create(:user)
      space.add_moderator(moderator)
      sign_in moderator

      get moderators_space_path(space)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Manage Moderators")
    end
  end

  describe "POST /spaces/:id/add_moderator" do
    it "requires login" do
      space = create(:space)
      user = create(:user)
      post add_moderator_space_path(space), params: { user_id: user.id }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not allow non-admins" do
      user = create(:user)
      space = create(:space)
      new_mod = create(:user)
      sign_in user

      post add_moderator_space_path(space), params: { user_id: new_mod.id }
      expect(response).to redirect_to(root_path)
    end

    it "allows admins to add moderators" do
      admin = create(:user, :admin)
      space = create(:space)
      new_mod = create(:user)
      sign_in admin

      expect {
        post add_moderator_space_path(space), params: { user_id: new_mod.id }
      }.to change { space.moderators.count }.by(1)

      expect(response).to redirect_to(moderators_space_path(space))
      expect(space.moderator?(new_mod)).to be true
    end

    it "allows space moderators to add moderators" do
      space = create(:space)
      existing_mod = create(:user)
      new_mod = create(:user)
      space.add_moderator(existing_mod)
      sign_in existing_mod

      expect {
        post add_moderator_space_path(space), params: { user_id: new_mod.id }
      }.to change { space.moderators.count }.by(1)

      expect(response).to redirect_to(moderators_space_path(space))
      expect(space.moderator?(new_mod)).to be true
    end
  end

  describe "DELETE /spaces/:id/remove_moderator" do
    it "requires login" do
      space = create(:space)
      moderator = create(:user)
      space.add_moderator(moderator)
      delete remove_moderator_space_path(space), params: { user_id: moderator.id }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not allow non-admins" do
      user = create(:user)
      space = create(:space)
      moderator = create(:user)
      space.add_moderator(moderator)
      sign_in user

      delete remove_moderator_space_path(space), params: { user_id: moderator.id }
      expect(response).to redirect_to(root_path)
    end

    it "allows admins to remove moderators" do
      admin = create(:user, :admin)
      space = create(:space)
      moderator = create(:user)
      space.add_moderator(moderator)
      sign_in admin

      expect {
        delete remove_moderator_space_path(space), params: { user_id: moderator.id }
      }.to change { space.moderators.count }.by(-1)

      expect(response).to redirect_to(moderators_space_path(space))
      expect(space.moderator?(moderator)).to be false
    end

    it "allows space moderators to remove other moderators" do
      space = create(:space)
      existing_mod = create(:user)
      other_mod = create(:user)
      space.add_moderator(existing_mod)
      space.add_moderator(other_mod)
      sign_in existing_mod

      expect {
        delete remove_moderator_space_path(space), params: { user_id: other_mod.id }
      }.to change { space.moderators.count }.by(-1)

      expect(response).to redirect_to(moderators_space_path(space))
      expect(space.moderator?(other_mod)).to be false
    end
  end
end
