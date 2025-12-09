# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value("user@example.com").for(:email) }
    it { is_expected.not_to allow_value("invalid-email").for(:email) }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
    it { is_expected.to validate_length_of(:username).is_at_least(3).is_at_most(30) }
    it { is_expected.to allow_value("valid_user123").for(:username) }
    it { is_expected.not_to allow_value("invalid user").for(:username) }
    it { is_expected.not_to allow_value("user@name").for(:username) }

    it { is_expected.to validate_presence_of(:role) }
  end

  describe "associations" do
    it { is_expected.to have_many(:questions).dependent(:destroy) }
    it { is_expected.to have_many(:answers).dependent(:destroy) }
    it { is_expected.to have_many(:votes).dependent(:destroy) }
    it { is_expected.to have_many(:question_votes).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:comment_votes).dependent(:destroy) }
    it { is_expected.to have_many(:space_subscriptions).dependent(:destroy) }
    it { is_expected.to have_many(:subscribed_spaces).through(:space_subscriptions).source(:space) }
    it { is_expected.to have_many(:space_moderators).dependent(:destroy) }
    it { is_expected.to have_many(:moderated_spaces).through(:space_moderators).source(:space) }
    it { is_expected.to have_many(:space_publishers).dependent(:destroy) }
    it { is_expected.to have_many(:published_spaces).through(:space_publishers).source(:space) }
    it { is_expected.to have_many(:articles).dependent(:destroy) }
    it { is_expected.to have_many(:user_emails).dependent(:destroy) }
    it { is_expected.to have_one(:primary_user_email) }
  end

  describe "enums" do
    # Note: moderator is per-space via SpaceModerator, not a global role
    it { is_expected.to define_enum_for(:role).with_values(user: 0, admin: 2, system: 3) }
  end

  describe ".search" do
    let!(:alice) { create(:user, username: "alice", full_name: "Alice Smith", email: "alice@example.com") }
    let!(:bob) { create(:user, username: "bob", full_name: "Bob Jones", email: "bob@test.com") }
    let!(:charlie) { create(:user, username: "charlie", full_name: nil, email: "charlie@example.com") }

    it "returns empty when query is blank" do
      expect(described_class.search("")).to be_empty
      expect(described_class.search(nil)).to be_empty
    end

    it "searches by username" do
      expect(described_class.search("alice")).to include(alice)
      expect(described_class.search("alice")).not_to include(bob)
    end

    it "searches by full_name" do
      expect(described_class.search("Smith")).to include(alice)
      expect(described_class.search("Jones")).to include(bob)
    end

    it "does not search by email" do
      expect(described_class.search("test.com")).not_to include(bob)
      expect(described_class.search("example.com")).not_to include(alice, charlie)
    end

    it "is case insensitive" do
      expect(described_class.search("ALICE")).to include(alice)
      expect(described_class.search("alice")).to include(alice)
    end

    it "matches partial strings" do
      expect(described_class.search("ali")).to include(alice)
      expect(described_class.search("ob")).to include(bob)
    end

    it "orders results by username" do
      results = described_class.search("alice")
      expect(results.to_a).to eq([ alice ])
    end

    it "limits results to 10" do
      15.times do |i|
        create(:user, username: "srchuser#{i}", email: "srchuser#{i}@test.com")
      end
      results = described_class.search("srchuser")
      expect(results.count).to eq(10)
    end
  end

  describe "callbacks" do
    describe "before_validation :normalize_email" do
      it "downcases and strips email" do
        user = build(:user, email: "  USER@EXAMPLE.COM  ")
        user.valid?
        expect(user.email).to eq("user@example.com")
      end
    end
  end

  describe "#to_param" do
    it "returns the username" do
      user = build(:user, username: "testuser")
      expect(user.to_param).to eq("testuser")
    end
  end

  describe "#display_name" do
    it "returns full_name when present" do
      user = build(:user, username: "testuser", full_name: "Test User")
      expect(user.display_name).to eq("Test User")
    end

    it "returns username when full_name is blank" do
      user = build(:user, username: "testuser", full_name: nil)
      expect(user.display_name).to eq("testuser")
    end

    it "returns username when full_name is empty string" do
      user = build(:user, username: "testuser", full_name: "")
      expect(user.display_name).to eq("testuser")
    end
  end

  describe "#has_solved_answer?" do
    it "returns true when user has a solved answer" do
      user = create(:user)
      create(:answer, user: user, is_correct: true)
      expect(user.has_solved_answer?).to be true
    end

    it "returns false when user has no solved answers" do
      user = create(:user)
      create(:answer, user: user, is_correct: false)
      expect(user.has_solved_answer?).to be false
    end

    it "returns false when user has no answers" do
      user = create(:user)
      expect(user.has_solved_answer?).to be false
    end
  end

  describe "#admin?" do
    it "returns true for admin users" do
      user = build(:user, :admin)
      expect(user.admin?).to be true
    end

    it "returns false for non-admin users" do
      user = build(:user)
      expect(user.admin?).to be false
    end
  end

  describe "#system?" do
    it "returns true for system users" do
      user = build(:user, role: :system)
      expect(user.system?).to be true
    end

    it "returns false for non-system users" do
      user = build(:user)
      expect(user.system?).to be false
    end
  end

  describe ".robot" do
    it "returns the system user when one exists" do
      robot = create(:user, role: :system, username: "robot")
      expect(described_class.robot).to eq(robot)
    end

    it "returns nil when no system user exists" do
      expect(described_class.robot).to be_nil
    end
  end

  describe "#moderator?" do
    it "returns true for users who moderate at least one space" do
      user = create(:user)
      space = create(:space)
      space.add_moderator(user)
      expect(user.moderator?).to be true
    end

    it "returns false for users who moderate no spaces" do
      user = create(:user)
      expect(user.moderator?).to be false
    end
  end

  describe "#can_moderate?" do
    let(:space) { create(:space) }
    let(:user) { create(:user) }

    it "returns true for admin users" do
      admin = create(:user, :admin)
      expect(admin.can_moderate?(space)).to be true
    end

    it "returns true for space moderators" do
      create(:space_moderator, space: space, user: user)
      expect(user.can_moderate?(space)).to be true
    end

    it "returns false for regular users" do
      expect(user.can_moderate?(space)).to be false
    end
  end

  describe "#publisher?" do
    it "returns true for users who publish in at least one space" do
      user = create(:user)
      space = create(:space)
      create(:space_publisher, user: user, space: space)
      expect(user.publisher?).to be true
    end

    it "returns false for users who publish in no spaces" do
      user = create(:user)
      expect(user.publisher?).to be false
    end
  end

  describe "#can_publish?" do
    let(:space) { create(:space) }
    let(:user) { create(:user) }

    it "returns true for admin users" do
      admin = create(:user, :admin)
      expect(admin.can_publish?(space)).to be true
    end

    it "returns true for space moderators" do
      create(:space_moderator, space: space, user: user)
      expect(user.can_publish?(space)).to be true
    end

    it "returns true for space publishers" do
      create(:space_publisher, space: space, user: user)
      expect(user.can_publish?(space)).to be true
    end

    it "returns false for regular users" do
      expect(user.can_publish?(space)).to be false
    end
  end

  describe "#questions_count" do
    it "returns the count of user's questions" do
      user = create(:user)
      create_list(:question, 3, user: user)
      expect(user.questions_count).to eq(3)
    end
  end

  describe "#answers_count" do
    it "returns the count of user's answers" do
      user = create(:user)
      create_list(:answer, 5, user: user)
      expect(user.answers_count).to eq(5)
    end
  end

  describe "#solved_answers_count" do
    it "returns the count of user's answers marked as solved by moderators" do
      user = create(:user)
      create_list(:answer, 3, user: user, is_correct: false)
      create_list(:answer, 2, user: user, is_correct: true)
      expect(user.solved_answers_count).to eq(2)
    end
  end

  describe "#best_answers_count" do
    it "returns 0 when user has no answers" do
      user = create(:user)
      expect(user.best_answers_count).to eq(0)
    end

    it "returns count of user's highest-voted answers per question" do
      user = create(:user)
      other_user = create(:user)
      question1 = create(:question)
      question2 = create(:question)

      # User has highest-voted answer on question1
      create(:answer, question: question1, user: user, vote_score: 10)
      create(:answer, question: question1, user: other_user, vote_score: 5)

      # Other user has highest-voted answer on question2
      create(:answer, question: question2, user: user, vote_score: 3)
      create(:answer, question: question2, user: other_user, vote_score: 8)

      expect(user.best_answers_count).to eq(1)
    end

    it "counts multiple best answers across different questions" do
      user = create(:user)
      other_user = create(:user)
      question1 = create(:question)
      question2 = create(:question)
      question3 = create(:question)

      # User has highest-voted on question1 and question2
      create(:answer, question: question1, user: user, vote_score: 10)
      create(:answer, question: question2, user: user, vote_score: 5)
      create(:answer, question: question3, user: other_user, vote_score: 20)

      expect(user.best_answers_count).to eq(2)
    end

    it "uses oldest answer as tiebreaker when vote scores are equal" do
      user = create(:user)
      other_user = create(:user)
      question = create(:question)

      # Other user's answer is older but same score - they win
      create(:answer, question: question, user: other_user, vote_score: 5, created_at: 2.days.ago)
      create(:answer, question: question, user: user, vote_score: 5, created_at: 1.day.ago)

      expect(user.best_answers_count).to eq(0)
      expect(other_user.best_answers_count).to eq(1)
    end
  end

  describe "#comments_count" do
    it "returns the count of user's comments" do
      user = create(:user)
      question = create(:question)
      create_list(:comment, 4, user: user, commentable: question)
      expect(user.comments_count).to eq(4)
    end
  end

  describe "#karma" do
    it "returns 0 for a user with no activity" do
      user = create(:user)
      expect(user.karma).to eq(0)
    end

    it "includes karma from questions" do
      user = create(:user)
      create(:question, user: user, vote_score: 5)
      # 5 (base for question) + 5 (vote score) = 10
      expect(user.karma).to eq(10)
    end

    it "includes karma from answers" do
      user = create(:user)
      create(:answer, user: user, vote_score: 3)
      # 10 (base for answer) + 3 (vote score) = 13
      expect(user.karma).to eq(13)
    end

    it "includes bonus karma for solved answers" do
      user = create(:user)
      create(:answer, user: user, is_correct: true, vote_score: 0)
      # 10 (base for answer) + 15 (solved bonus) + 0 (vote score) = 25
      expect(user.karma).to eq(25)
    end

    it "includes karma from comments" do
      user = create(:user)
      question = create(:question)
      create(:comment, user: user, commentable: question, vote_score: 2)
      # 0 (no questions/answers) + 2 (comment vote score) = 2
      expect(user.karma).to eq(2)
    end

    it "calculates total karma from all sources" do
      user = create(:user)
      question = create(:question)
      create(:question, user: user, vote_score: 10)       # 5 + 10 = 15
      create(:answer, user: user, is_correct: true, vote_score: 5) # 10 + 15 + 5 = 30
      create(:answer, user: user, is_correct: false, vote_score: 3) # 10 + 3 = 13
      create(:comment, user: user, commentable: question, vote_score: 2) # 2
      # Total: 15 + 30 + 13 + 2 = 60
      expect(user.karma).to eq(60)
    end
  end

  describe "#ldap_user?" do
    it "returns true when user has ldap provider" do
      user = create(:user, provider: "ldap")
      expect(user.ldap_user?).to be true
    end

    it "returns false when user has no provider" do
      user = create(:user, provider: nil)
      expect(user.ldap_user?).to be false
    end

    it "returns false when user has different provider" do
      user = create(:user, provider: "google")
      expect(user.ldap_user?).to be false
    end
  end

  describe "#add_email" do
    let(:user) { create(:user) }

    it "creates a new unverified email for the user" do
      result = user.add_email("new@example.com")
      expect(result).to be_a(UserEmail)
      expect(result.email).to eq("new@example.com")
      expect(result.verified?).to be false
      expect(result.primary?).to be false
    end
  end

  describe "#has_verified_email?" do
    let(:user) { create(:user) }

    it "returns true when user has a verified email matching the address" do
      create(:user_email, :verified, user: user, email: "verified@example.com")
      expect(user.has_verified_email?("verified@example.com")).to be true
    end

    it "returns false when email is unverified" do
      create(:user_email, :unverified, user: user, email: "unverified@example.com")
      expect(user.has_verified_email?("unverified@example.com")).to be false
    end

    it "returns false when email does not exist" do
      expect(user.has_verified_email?("nonexistent@example.com")).to be false
    end

    it "is case insensitive" do
      create(:user_email, :verified, user: user, email: "verified@example.com")
      expect(user.has_verified_email?("VERIFIED@EXAMPLE.COM")).to be true
    end
  end

  describe ".find_for_authentication" do
    let!(:user) { create(:user, email: "primary@example.com") }

    it "delegates to find_for_database_authentication" do
      result = described_class.find_for_authentication(email: "primary@example.com")
      expect(result).to eq(user)
    end
  end

  describe ".find_for_database_authentication" do
    let!(:user) { create(:user, email: "test@example.com") }

    context "with nil email" do
      it "returns nil" do
        result = described_class.find_for_database_authentication(email: nil)
        expect(result).to be_nil
      end
    end

    context "with blank email" do
      it "returns nil" do
        result = described_class.find_for_database_authentication(email: "")
        expect(result).to be_nil
      end
    end
  end

  describe ".find_first_by_auth_conditions" do
    let!(:user) { create(:user, email: "test@example.com") }

    context "with valid verified email" do
      it "returns the user" do
        result = described_class.find_first_by_auth_conditions(email: "test@example.com")
        expect(result).to eq(user)
      end
    end

    context "with nil email" do
      it "returns nil" do
        result = described_class.find_first_by_auth_conditions(email: nil)
        expect(result).to be_nil
      end
    end

    context "with blank email" do
      it "returns nil" do
        result = described_class.find_first_by_auth_conditions(email: "")
        expect(result).to be_nil
      end
    end

    context "with unverified email" do
      it "returns nil" do
        unverified = create(:user_email, :unverified, user: user, email: "unverified@example.com")
        result = described_class.find_first_by_auth_conditions(email: "unverified@example.com")
        expect(result).to be_nil
      end
    end
  end

  describe "after_create callback: create_primary_user_email" do
    context "when user has blank email" do
      it "does not create a primary user_email" do
        # Use build and save to bypass validation
        user = build(:user, email: "temp@example.com")
        user.save!
        user.user_emails.destroy_all
        user.update_column(:email, "")
        user.reload

        # Manually trigger callback
        user.send(:create_primary_user_email)

        expect(user.user_emails.count).to eq(0)
      end
    end

    context "when email already exists in user_emails" do
      it "does not create a duplicate" do
        user = create(:user, email: "existing@example.com")
        initial_count = user.user_emails.count

        # Manually trigger callback again
        user.send(:create_primary_user_email)

        expect(user.user_emails.count).to eq(initial_count)
      end
    end
  end

  describe "UnverifiedEmailError" do
    it "stores the email address" do
      error = User::UnverifiedEmailError.new("test@example.com")
      expect(error.email).to eq("test@example.com")
    end

    it "has a descriptive message" do
      error = User::UnverifiedEmailError.new("test@example.com")
      expect(error.message).to include("test@example.com")
      expect(error.message).to include("verified")
    end
  end

  describe ".from_omniauth" do
    let(:ldap_server) { create(:ldap_server) }
    let(:auth_hash) do
      OpenStruct.new(
        provider: "ldap",
        uid: "testuser",
        info: OpenStruct.new(
          email: "testuser@example.com",
          name: "Test User",
          nickname: "testuser"
        ),
        extra: OpenStruct.new(
          raw_info: OpenStruct.new(
            dn: "uid=testuser,ou=users,dc=example,dc=com"
          )
        )
      )
    end

    context "when user does not exist" do
      it "creates a new user" do
        expect {
          User.from_omniauth(auth_hash, ldap_server)
        }.to change(User, :count).by(1)
      end

      it "sets LDAP attributes" do
        user = User.from_omniauth(auth_hash, ldap_server)
        expect(user.provider).to eq("ldap")
        expect(user.uid).to eq("testuser")
        expect(user.ldap_dn).to eq("uid=testuser,ou=users,dc=example,dc=com")
        expect(user.email).to eq("testuser@example.com")
        expect(user.full_name).to eq("Test User")
      end
    end

    context "when user exists with same email" do
      let!(:existing_user) { create(:user, email: "testuser@example.com") }

      it "updates existing user with LDAP info" do
        expect {
          User.from_omniauth(auth_hash, ldap_server)
        }.not_to change(User, :count)

        existing_user.reload
        expect(existing_user.provider).to eq("ldap")
        expect(existing_user.uid).to eq("testuser")
      end
    end

    context "when user exists with same provider and uid" do
      let!(:existing_user) { create(:user, provider: "ldap", uid: "testuser", email: "old@example.com") }

      it "finds user by provider and uid" do
        user = User.from_omniauth(auth_hash, ldap_server)
        expect(user.id).to eq(existing_user.id)
      end
    end

    context "when auth hash has missing extra data" do
      let(:auth_hash_no_extra) do
        OpenStruct.new(
          provider: "ldap",
          uid: "noextra",
          info: OpenStruct.new(
            email: "noextra@example.com",
            name: "No Extra User",
            nickname: "noextra"
          ),
          extra: nil
        )
      end

      it "creates user with nil ldap_dn" do
        user = User.from_omniauth(auth_hash_no_extra, ldap_server)
        expect(user.ldap_dn).to be_nil
      end
    end

    context "when auth hash has extra but no raw_info" do
      let(:auth_hash_no_raw_info) do
        OpenStruct.new(
          provider: "ldap",
          uid: "norawinfo",
          info: OpenStruct.new(
            email: "norawinfo@example.com",
            name: "No Raw Info User",
            nickname: "norawinfo"
          ),
          extra: OpenStruct.new(raw_info: nil)
        )
      end

      it "creates user with nil ldap_dn" do
        user = User.from_omniauth(auth_hash_no_raw_info, ldap_server)
        expect(user.ldap_dn).to be_nil
      end
    end

    context "when email exists but is unverified" do
      let!(:existing_user) { create(:user, email: "other@example.com") }
      let!(:unverified_email) { create(:user_email, :unverified, user: existing_user, email: "testuser@example.com") }

      it "raises UnverifiedEmailError" do
        expect {
          User.from_omniauth(auth_hash, ldap_server)
        }.to raise_error(User::UnverifiedEmailError, /testuser@example.com/)
      end

      it "includes the email in the error" do
        error = nil
        begin
          User.from_omniauth(auth_hash, ldap_server)
        rescue User::UnverifiedEmailError => e
          error = e
        end
        expect(error.email).to eq("testuser@example.com")
      end
    end

    context "when auth hash has nil email" do
      let(:auth_hash_nil_email) do
        OpenStruct.new(
          provider: "ldap",
          uid: "nilemail",
          info: OpenStruct.new(
            email: nil,
            name: "No Email User",
            nickname: "nilemail"
          ),
          extra: OpenStruct.new(
            raw_info: OpenStruct.new(
              dn: "uid=nilemail,ou=users,dc=example,dc=com"
            )
          )
        )
      end

      it "handles nil email gracefully in processing" do
        # The email becomes empty string after safe navigation
        # This should fail validation, but let's verify the code path works
        expect {
          User.from_omniauth(auth_hash_nil_email, ldap_server)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe ".generate_unique_username" do
    it "returns base username when not taken" do
      expect(User.generate_unique_username("newuser")).to eq("newuser")
    end

    it "sanitizes special characters" do
      expect(User.generate_unique_username("user@domain.com")).to eq("user_domain_com")
    end

    it "truncates long usernames to 25 characters" do
      long_name = "a" * 50
      expect(User.generate_unique_username(long_name).length).to eq(25)
    end

    it "appends counter when username is taken" do
      create(:user, username: "takenuser")
      expect(User.generate_unique_username("takenuser")).to eq("takenuser_1")
    end

    it "increments counter for multiple conflicts" do
      create(:user, username: "popular")
      create(:user, username: "popular_1")
      create(:user, username: "popular_2")
      expect(User.generate_unique_username("popular")).to eq("popular_3")
    end
  end

  describe "#all_subscribed_spaces" do
    let(:user) { create(:user) }
    let(:space1) { create(:space) }
    let(:space2) { create(:space) }

    context "with only manual subscriptions" do
      before do
        create(:space_subscription, user: user, space: space1)
      end

      it "returns manually subscribed spaces" do
        expect(user.all_subscribed_spaces).to include(space1)
        expect(user.all_subscribed_spaces).not_to include(space2)
      end
    end

    context "with LDAP subscriptions" do
      let(:ldap_user) { create(:user, provider: "ldap", ldap_dn: "uid=test,ou=users,dc=example,dc=com") }
      let(:ldap_server) { create(:ldap_server, enabled: true) }
      let(:ldap_mapping) { create(:ldap_group_mapping, ldap_server: ldap_server) }

      before do
        create(:ldap_group_mapping_space, ldap_group_mapping: ldap_mapping, space: space2)
      end

      it "returns LDAP-mapped spaces" do
        result = ldap_user.all_subscribed_spaces
        expect(result).to include(space2)
      end

      it "excludes opted-out LDAP spaces" do
        create(:space_opt_out, user: ldap_user, space: space2, ldap_group_mapping: ldap_mapping)
        result = ldap_user.all_subscribed_spaces
        expect(result).not_to include(space2)
      end

      it "combines manual and LDAP subscriptions" do
        create(:space_subscription, user: ldap_user, space: space1)
        result = ldap_user.all_subscribed_spaces
        expect(result).to include(space1, space2)
      end
    end

    context "with no subscriptions" do
      it "returns empty collection" do
        expect(user.all_subscribed_spaces).to be_empty
      end
    end
  end

  describe "#subscribed_to?" do
    let(:user) { create(:user) }
    let(:space) { create(:space) }

    context "with manual subscription" do
      before do
        create(:space_subscription, user: user, space: space)
      end

      it "returns true for subscribed space" do
        expect(user.subscribed_to?(space)).to be true
      end
    end

    context "with LDAP subscription" do
      let(:ldap_user) { create(:user, provider: "ldap", ldap_dn: "uid=test,ou=users,dc=example,dc=com") }
      let(:ldap_server) { create(:ldap_server, enabled: true) }
      let(:ldap_mapping) { create(:ldap_group_mapping, ldap_server: ldap_server) }

      before do
        create(:ldap_group_mapping_space, ldap_group_mapping: ldap_mapping, space: space)
      end

      it "returns true for LDAP-mapped space" do
        expect(ldap_user.subscribed_to?(space)).to be true
      end

      it "returns false if opted out of LDAP space" do
        create(:space_opt_out, user: ldap_user, space: space, ldap_group_mapping: ldap_mapping)
        expect(ldap_user.subscribed_to?(space)).to be false
      end
    end

    context "with no subscription" do
      it "returns false" do
        expect(user.subscribed_to?(space)).to be false
      end
    end
  end

  describe "#ldap_subscribed_space_ids" do
    let(:space1) { create(:space) }
    let(:space2) { create(:space) }

    context "when user is not an LDAP user" do
      let(:user) { create(:user, provider: nil) }

      it "returns empty array" do
        expect(user.ldap_subscribed_space_ids).to eq([])
      end
    end

    context "when LDAP user has no ldap_dn" do
      let(:ldap_user) { create(:user, provider: "ldap", ldap_dn: nil) }

      it "returns empty array" do
        expect(ldap_user.ldap_subscribed_space_ids).to eq([])
      end
    end

    context "when LDAP user with valid ldap_dn" do
      let(:ldap_user) { create(:user, provider: "ldap", ldap_dn: "uid=test,ou=users,dc=example,dc=com") }
      let(:ldap_server) { create(:ldap_server, enabled: true) }
      let(:disabled_server) { create(:ldap_server, enabled: false) }
      let(:ldap_mapping) { create(:ldap_group_mapping, ldap_server: ldap_server) }
      let(:disabled_mapping) { create(:ldap_group_mapping, ldap_server: disabled_server) }

      before do
        create(:ldap_group_mapping_space, ldap_group_mapping: ldap_mapping, space: space1)
        create(:ldap_group_mapping_space, ldap_group_mapping: disabled_mapping, space: space2)
      end

      it "returns space IDs from enabled LDAP servers" do
        expect(ldap_user.ldap_subscribed_space_ids).to include(space1.id)
      end

      it "excludes spaces from disabled LDAP servers" do
        expect(ldap_user.ldap_subscribed_space_ids).not_to include(space2.id)
      end

      it "excludes opted-out spaces" do
        create(:space_opt_out, user: ldap_user, space: space1, ldap_group_mapping: ldap_mapping)
        expect(ldap_user.ldap_subscribed_space_ids).not_to include(space1.id)
      end
    end
  end

  describe "#ldap_subscription_for" do
    let(:space) { create(:space) }

    context "when user is not an LDAP user" do
      let(:user) { create(:user, provider: nil) }

      it "returns nil" do
        expect(user.ldap_subscription_for(space)).to be_nil
      end
    end

    context "when LDAP user has no ldap_dn" do
      let(:ldap_user) { create(:user, provider: "ldap", ldap_dn: nil) }

      it "returns nil" do
        expect(ldap_user.ldap_subscription_for(space)).to be_nil
      end
    end

    context "when LDAP user with valid ldap_dn" do
      let(:ldap_user) { create(:user, provider: "ldap", ldap_dn: "uid=test,ou=users,dc=example,dc=com") }
      let(:ldap_server) { create(:ldap_server, enabled: true) }
      let(:disabled_server) { create(:ldap_server, enabled: false) }
      let(:ldap_mapping) { create(:ldap_group_mapping, ldap_server: ldap_server, group_pattern: "cn=devops") }
      let(:disabled_mapping) { create(:ldap_group_mapping, ldap_server: disabled_server, group_pattern: "cn=other") }
      let(:other_space) { create(:space) }

      before do
        create(:ldap_group_mapping_space, ldap_group_mapping: ldap_mapping, space: space)
        create(:ldap_group_mapping_space, ldap_group_mapping: disabled_mapping, space: other_space)
      end

      it "returns the LDAP mapping for a space from an enabled server" do
        result = ldap_user.ldap_subscription_for(space)
        expect(result).to eq(ldap_mapping)
      end

      it "returns nil for a space from a disabled server" do
        expect(ldap_user.ldap_subscription_for(other_space)).to be_nil
      end

      it "returns nil if user has opted out of the space" do
        create(:space_opt_out, user: ldap_user, space: space, ldap_group_mapping: ldap_mapping)
        expect(ldap_user.ldap_subscription_for(space)).to be_nil
      end

      it "returns nil for a space with no LDAP mapping" do
        unrelated_space = create(:space)
        expect(ldap_user.ldap_subscription_for(unrelated_space)).to be_nil
      end
    end
  end

  describe "#publishable_spaces" do
    let!(:space1) { create(:space) }
    let!(:space2) { create(:space) }
    let!(:space3) { create(:space) }

    context "when user is admin" do
      let(:admin) { create(:user, :admin) }

      it "returns all spaces" do
        result = admin.publishable_spaces
        expect(result).to include(space1, space2, space3)
      end
    end

    context "when user is moderator of spaces" do
      let(:user) { create(:user) }

      before do
        space1.add_moderator(user)
      end

      it "returns moderated spaces" do
        expect(user.publishable_spaces).to include(space1)
        expect(user.publishable_spaces).not_to include(space2, space3)
      end
    end

    context "when user is publisher in spaces" do
      let(:user) { create(:user) }

      before do
        create(:space_publisher, user: user, space: space2)
      end

      it "returns published spaces" do
        expect(user.publishable_spaces).to include(space2)
        expect(user.publishable_spaces).not_to include(space1, space3)
      end
    end
  end
end
