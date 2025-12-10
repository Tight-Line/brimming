# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Profile" do
  let(:user) { create(:user, full_name: "Test User") }

  describe "GET /settings/profile/edit" do
    context "when not logged in" do
      it "redirects to login" do
        get edit_settings_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      before { sign_in user }

      it "returns http success" do
        get edit_settings_profile_path
        expect(response).to have_http_status(:success)
      end

      it "displays the profile form" do
        get edit_settings_profile_path
        expect(response.body).to include("Profile Settings")
        expect(response.body).to include("Display Name")
        expect(response.body).to include("Timezone")
      end

      it "displays current user information" do
        get edit_settings_profile_path
        expect(response.body).to include(user.full_name)
        expect(response.body).to include(user.email)
      end

      it "displays all user emails" do
        secondary = create(:user_email, :verified, user: user, email: "secondary@example.com")
        get edit_settings_profile_path
        expect(response.body).to include(user.email)
        expect(response.body).to include("secondary@example.com")
      end
    end
  end

  describe "PATCH /settings/profile" do
    context "when not logged in" do
      it "redirects to login" do
        patch settings_profile_path, params: { user: { full_name: "New Name" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      before { sign_in user }

      it "updates the user's full_name" do
        patch settings_profile_path, params: { user: { full_name: "Updated Name" } }
        expect(user.reload.full_name).to eq("Updated Name")
      end

      it "redirects with success notice" do
        patch settings_profile_path, params: { user: { full_name: "Updated Name" } }
        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:notice]).to eq("Profile updated successfully.")
      end

      context "with invalid params" do
        before do
          allow_any_instance_of(User).to receive(:update).and_return(false)
        end

        it "renders the edit form with unprocessable entity status" do
          patch settings_profile_path, params: { user: { full_name: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe "POST /settings/profile/add_email" do
    context "when not logged in" do
      it "redirects to login" do
        post add_email_settings_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      before do
        sign_in user
        allow(UserEmailMailer).to receive_message_chain(:verification_email, :deliver_later)
      end

      it "adds a new email and sends verification" do
        expect {
          post add_email_settings_profile_path, params: { email: "new@example.com" }
        }.to change(UserEmail, :count).by(1)

        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:notice]).to include("Verification email sent")
      end

      it "rejects blank email" do
        post add_email_settings_profile_path, params: { email: "" }
        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:alert]).to eq("Please enter an email address.")
      end

      it "rejects nil email" do
        post add_email_settings_profile_path, params: {}
        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:alert]).to eq("Please enter an email address.")
      end

      it "rejects duplicate email" do
        post add_email_settings_profile_path, params: { email: user.email }
        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:alert]).to eq("You already have this email address.")
      end

      it "rejects invalid email format" do
        post add_email_settings_profile_path, params: { email: "not-an-email" }
        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:alert]).to include("Email is invalid")
      end
    end
  end

  describe "DELETE /settings/profile/remove_email" do
    context "when not logged in" do
      it "redirects to login" do
        delete remove_email_settings_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      before { sign_in user }

      it "removes a non-primary email" do
        secondary = create(:user_email, :verified, user: user, email: "secondary@example.com")
        expect {
          delete remove_email_settings_profile_path(email_id: secondary.id)
        }.to change(UserEmail, :count).by(-1)

        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:notice]).to eq("Email address removed.")
      end

      it "refuses to remove primary email" do
        primary = user.user_emails.primary.first
        delete remove_email_settings_profile_path(email_id: primary.id)
        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:alert]).to eq("Cannot remove your primary email address.")
      end

      it "handles invalid email_id" do
        delete remove_email_settings_profile_path(email_id: 99999)
        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:alert]).to eq("Email not found.")
      end
    end
  end

  describe "POST /settings/profile/set_primary_email" do
    context "when not logged in" do
      it "redirects to login" do
        post set_primary_email_settings_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      before { sign_in user }

      it "sets a verified email as primary" do
        secondary = create(:user_email, :verified, user: user, email: "secondary@example.com")
        post set_primary_email_settings_profile_path(email_id: secondary.id)

        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:notice]).to include("Primary email updated")
        expect(secondary.reload.primary?).to be true
        expect(user.reload.email).to eq("secondary@example.com")
      end

      it "refuses to set unverified email as primary" do
        unverified = create(:user_email, :unverified, user: user, email: "unverified@example.com")
        post set_primary_email_settings_profile_path(email_id: unverified.id)

        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:alert]).to eq("Only verified emails can be set as primary.")
      end

      it "handles invalid email_id" do
        post set_primary_email_settings_profile_path(email_id: 99999)
        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:alert]).to eq("Email not found.")
      end
    end
  end

  describe "POST /settings/profile/resend_verification" do
    context "when not logged in" do
      it "redirects to login" do
        post resend_verification_settings_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      before do
        sign_in user
        allow(UserEmailMailer).to receive_message_chain(:verification_email, :deliver_later)
      end

      it "sends verification for unverified email" do
        unverified = create(:user_email, :unverified, user: user, email: "unverified@example.com")
        post resend_verification_settings_profile_path(email_id: unverified.id)

        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:notice]).to include("Verification email sent")
      end

      it "refuses to send verification for already verified email" do
        verified = create(:user_email, :verified, user: user, email: "verified@example.com")
        post resend_verification_settings_profile_path(email_id: verified.id)

        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:alert]).to eq("This email is already verified.")
      end

      it "handles invalid email_id" do
        post resend_verification_settings_profile_path(email_id: 99999)
        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:alert]).to eq("Email not found.")
      end
    end
  end
end
