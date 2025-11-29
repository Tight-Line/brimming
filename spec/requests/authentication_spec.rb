# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication" do
  describe "GET /users/sign_up" do
    it "returns http success" do
      get new_user_registration_path

      expect(response).to have_http_status(:success)
    end

    it "displays the registration form" do
      get new_user_registration_path

      expect(response.body).to include("Sign up")
      expect(response.body).to include("Username")
      expect(response.body).to include("Email")
      expect(response.body).to include("Password")
    end
  end

  describe "POST /users" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          user: {
            username: "newuser",
            email: "newuser@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      it "creates a new user" do
        expect {
          post user_registration_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "redirects to root path" do
        post user_registration_path, params: valid_params

        expect(response).to redirect_to(root_path)
      end

      it "sets the username" do
        post user_registration_path, params: valid_params

        expect(User.last.username).to eq("newuser")
      end

      it "signs in the user" do
        post user_registration_path, params: valid_params

        follow_redirect!
        expect(response.body).to include("newuser")
      end
    end

    context "with invalid parameters" do
      it "does not create a user without username" do
        expect {
          post user_registration_path, params: {
            user: {
              email: "test@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        }.not_to change(User, :count)
      end

      it "does not create a user with invalid username" do
        expect {
          post user_registration_path, params: {
            user: {
              username: "ab",
              email: "test@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        }.not_to change(User, :count)
      end

      it "does not create a user with duplicate email" do
        create(:user, email: "existing@example.com")

        expect {
          post user_registration_path, params: {
            user: {
              username: "newuser",
              email: "existing@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        }.not_to change(User, :count)
      end

      it "does not create a user with duplicate username" do
        create(:user, username: "existinguser")

        expect {
          post user_registration_path, params: {
            user: {
              username: "existinguser",
              email: "new@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        }.not_to change(User, :count)
      end

      it "does not create a user with mismatched passwords" do
        expect {
          post user_registration_path, params: {
            user: {
              username: "newuser",
              email: "test@example.com",
              password: "password123",
              password_confirmation: "differentpassword"
            }
          }
        }.not_to change(User, :count)
      end
    end
  end

  describe "GET /users/sign_in" do
    it "returns http success" do
      get new_user_session_path

      expect(response).to have_http_status(:success)
    end

    it "displays the login form" do
      get new_user_session_path

      expect(response.body).to include("Log in")
      expect(response.body).to include("Email")
      expect(response.body).to include("Password")
    end
  end

  describe "POST /users/sign_in" do
    let(:user) { create(:user, password: "password123") }

    context "with valid credentials" do
      it "signs in the user" do
        post user_session_path, params: {
          user: { email: user.email, password: "password123" }
        }

        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid credentials" do
      it "does not sign in with wrong password" do
        post user_session_path, params: {
          user: { email: user.email, password: "wrongpassword" }
        }

        expect(response.body).to include("Invalid")
      end

      it "does not sign in with non-existent email" do
        post user_session_path, params: {
          user: { email: "nonexistent@example.com", password: "password123" }
        }

        expect(response.body).to include("Invalid")
      end
    end
  end

  describe "DELETE /users/sign_out" do
    let(:user) { create(:user) }

    it "signs out the user" do
      sign_in user

      delete destroy_user_session_path

      expect(response).to redirect_to(root_path)
    end
  end
end
