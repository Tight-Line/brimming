# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserEmail do
  include ActiveSupport::Testing::TimeHelpers

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:user_email) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value("user@example.com").for(:email) }
    it { is_expected.not_to allow_value("invalid-email").for(:email) }
    it { is_expected.not_to allow_value("@example.com").for(:email) }

    context "when setting primary" do
      let(:user) { create(:user) }

      it "allows one primary email per user" do
        # User already has a primary email from the after_create callback
        expect(user.user_emails.primary.count).to eq(1)
        second_primary = build(:user_email, :primary, user: user)
        expect(second_primary).not_to be_valid
        expect(second_primary.errors[:primary]).to include("email already exists for this user")
      end

      it "allows multiple non-primary emails per user" do
        create(:user_email, user: user, primary: false)
        second_email = build(:user_email, user: user, primary: false)
        expect(second_email).to be_valid
      end

      it "skips primary validation when user is nil" do
        # Build without a user to test the guard clause
        email = build(:user_email, :primary, user: nil, email: "orphan@example.com")
        email.valid?
        # Should not fail on the primary validation, but will fail on user presence
        expect(email.errors[:primary]).to be_empty
        expect(email.errors[:user]).to include("must exist")
      end
    end
  end

  describe "callbacks" do
    describe "before_validation :normalize_email" do
      it "downcases and strips email" do
        email = build(:user_email, email: "  USER@EXAMPLE.COM  ")
        email.valid?
        expect(email.email).to eq("user@example.com")
      end
    end

    describe "before_create :generate_verification_token" do
      it "generates a verification token for unverified emails" do
        email = build(:user_email, verified: false, verification_token: nil)
        email.save!
        expect(email.verification_token).to be_present
      end

      it "does not generate a verification token for verified emails" do
        email = build(:user_email, :verified)
        email.save!
        expect(email.verification_token).to be_nil
      end
    end
  end

  describe "scopes" do
    # Create users and use their auto-created primary emails for testing
    let!(:user_with_verified) { create(:user) }
    let!(:user_with_unverified) { create(:user) }
    let!(:user_with_primary) { create(:user) }

    # The primary email is auto-created with the user
    let!(:primary_email) { user_with_primary.user_emails.primary.first }

    # Create additional emails for testing verified/unverified
    let!(:verified_email) { create(:user_email, :verified, user: user_with_verified) }
    let!(:unverified_email) { create(:user_email, :unverified, user: user_with_unverified) }

    describe ".verified" do
      it "returns only verified emails" do
        expect(described_class.verified).to include(verified_email, primary_email)
        expect(described_class.verified).not_to include(unverified_email)
      end
    end

    describe ".unverified" do
      it "returns only unverified emails" do
        expect(described_class.unverified).to include(unverified_email)
        expect(described_class.unverified).not_to include(verified_email, primary_email)
      end
    end

    describe ".primary" do
      it "returns only primary emails" do
        expect(described_class.primary).to include(primary_email)
        expect(described_class.primary).not_to include(verified_email, unverified_email)
      end
    end
  end

  describe ".find_user_by_verified_email" do
    let(:user) { create(:user) }
    let!(:verified_email) { create(:user_email, :verified, user: user, email: "verified@example.com") }
    let!(:unverified_email) { create(:user_email, :unverified, user: user, email: "unverified@example.com") }

    it "returns user for verified email" do
      expect(described_class.find_user_by_verified_email("verified@example.com")).to eq(user)
    end

    it "returns nil for unverified email" do
      expect(described_class.find_user_by_verified_email("unverified@example.com")).to be_nil
    end

    it "returns nil for non-existent email" do
      expect(described_class.find_user_by_verified_email("notfound@example.com")).to be_nil
    end

    it "is case insensitive" do
      expect(described_class.find_user_by_verified_email("VERIFIED@EXAMPLE.COM")).to eq(user)
    end
  end

  describe ".find_by_email" do
    let!(:email_record) { create(:user_email, email: "test@example.com") }

    it "finds email record by email address" do
      expect(described_class.find_by_email("test@example.com")).to eq(email_record)
    end

    it "is case insensitive" do
      expect(described_class.find_by_email("TEST@EXAMPLE.COM")).to eq(email_record)
    end

    it "returns nil for non-existent email" do
      expect(described_class.find_by_email("notfound@example.com")).to be_nil
    end
  end

  describe "#verify!" do
    let(:email) { create(:user_email, :unverified) }

    it "marks email as verified" do
      email.verify!
      expect(email.verified).to be true
    end

    it "sets verified_at timestamp" do
      travel_to Time.zone.local(2025, 1, 15, 12, 0, 0) do
        email.verify!
        expect(email.verified_at).to eq(Time.current)
      end
    end

    it "clears verification token" do
      email.verify!
      expect(email.verification_token).to be_nil
    end
  end

  describe "#mark_as_primary!" do
    let(:user) { create(:user) }
    # User already has a primary email from after_create callback
    let!(:old_primary) { user.user_emails.primary.first }
    let!(:new_primary) { create(:user_email, :verified, user: user, email: "new@example.com") }

    it "sets this email as primary" do
      new_primary.mark_as_primary!
      expect(new_primary.reload.primary).to be true
    end

    it "removes primary from other emails" do
      new_primary.mark_as_primary!
      expect(old_primary.reload.primary).to be false
    end

    it "syncs to user.email for Devise compatibility" do
      new_primary.mark_as_primary!
      expect(user.reload.email).to eq("new@example.com")
    end

    it "does nothing if already primary" do
      expect { old_primary.mark_as_primary! }.not_to change { old_primary.reload.primary }
    end

    it "raises error for unverified email" do
      unverified = create(:user_email, :unverified, user: user)
      expect { unverified.mark_as_primary! }.to raise_error("Cannot set unverified email as primary")
    end
  end

  describe "#send_verification!" do
    let(:email) { create(:user_email, :unverified) }

    before do
      allow(UserEmailMailer).to receive_message_chain(:verification_email, :deliver_later)
    end

    it "generates a new verification token" do
      old_token = email.verification_token
      email.send_verification!
      expect(email.verification_token).not_to eq(old_token)
    end

    it "sends verification email" do
      email.send_verification!
      expect(UserEmailMailer).to have_received(:verification_email).with(email)
    end
  end
end
