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

      it "signs in with a secondary verified email" do
        secondary = create(:user_email, :verified, user: user, email: "secondary@example.com")
        post user_session_path, params: {
          user: { email: "secondary@example.com", password: "password123" }
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

      it "does not sign in with an unverified email" do
        unverified = create(:user_email, :unverified, user: user, email: "unverified@example.com")
        post user_session_path, params: {
          user: { email: "unverified@example.com", password: "password123" }
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

  describe "POST /users/password (password reset)" do
    include ActiveJob::TestHelper

    let(:user) { create(:user) }

    context "with primary email" do
      it "sends reset instructions" do
        perform_enqueued_jobs do
          post user_password_path, params: {
            user: { email: user.email }
          }
        end

        expect(response).to redirect_to(new_user_session_path)
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end
    end

    context "with secondary verified email" do
      it "sends reset instructions" do
        secondary = create(:user_email, :verified, user: user, email: "secondary@example.com")
        ActionMailer::Base.deliveries.clear

        perform_enqueued_jobs do
          post user_password_path, params: {
            user: { email: "secondary@example.com" }
          }
        end

        expect(response).to redirect_to(new_user_session_path)
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end
    end

    context "with unverified email" do
      it "does not send reset instructions" do
        unverified = create(:user_email, :unverified, user: user, email: "unverified@example.com")
        ActionMailer::Base.deliveries.clear

        perform_enqueued_jobs do
          post user_password_path, params: {
            user: { email: "unverified@example.com" }
          }
        end

        # Devise shows the redirect but doesn't send the email for non-existent users
        # to prevent email enumeration attacks
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    context "with non-existent email" do
      it "does not send reset instructions" do
        ActionMailer::Base.deliveries.clear

        perform_enqueued_jobs do
          post user_password_path, params: {
            user: { email: "nonexistent@example.com" }
          }
        end

        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end
  end
end
