# frozen_string_literal: true

require "rails_helper"

RSpec.describe "EmailVerifications" do
  describe "GET /verify_email" do
    context "with valid unverified token" do
      let(:user) { create(:user) }
      let!(:user_email) { create(:user_email, :unverified, user: user) }

      it "verifies the email" do
        expect {
          get verify_email_path(token: user_email.verification_token)
        }.to change { user_email.reload.verified? }.from(false).to(true)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Your email address has been verified.")
      end

      it "sets verified_at timestamp" do
        get verify_email_path(token: user_email.verification_token)
        expect(user_email.reload.verified_at).to be_present
      end

      it "clears the verification token" do
        get verify_email_path(token: user_email.verification_token)
        expect(user_email.reload.verification_token).to be_nil
      end
    end

    context "with already verified email" do
      let(:user) { create(:user) }
      let!(:user_email) { create(:user_email, :verified, user: user) }

      before do
        # Manually set a token for testing (normally nil for verified emails)
        user_email.update_column(:verification_token, "test_token")
      end

      it "redirects with already verified notice" do
        get verify_email_path(token: "test_token")

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("This email has already been verified.")
      end
    end

    context "with invalid token" do
      it "redirects with error alert" do
        get verify_email_path(token: "invalid_token")

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Invalid or expired verification link.")
      end
    end

    context "with missing token" do
      it "redirects with error alert" do
        get verify_email_path(token: nil)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Invalid or expired verification link.")
      end
    end
  end
end
