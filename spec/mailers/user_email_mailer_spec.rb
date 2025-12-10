# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserEmailMailer do
  describe "#verification_email" do
    let(:user) { create(:user) }
    let(:user_email) { create(:user_email, :unverified, user: user, email: "new@example.com") }
    let(:mail) { described_class.verification_email(user_email) }

    it "renders the headers" do
      expect(mail.subject).to eq("Verify your email address")
      expect(mail.to).to eq([ "new@example.com" ])
      expect(mail.from).to eq([ ApplicationMailer.default[:from] ])
    end

    it "renders the body with verification link" do
      expect(mail.body.encoded).to include(user.display_name)
      expect(mail.body.encoded).to include("new@example.com")
      expect(mail.body.encoded).to include("verify_email")
      expect(mail.body.encoded).to include(user_email.verification_token)
    end
  end
end
