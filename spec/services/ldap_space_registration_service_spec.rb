# frozen_string_literal: true

require "rails_helper"

RSpec.describe LdapSpaceRegistrationService, type: :service do
  let(:user) { create(:user) }
  let(:ldap_server) { create(:ldap_server) }
  let(:space1) { create(:space, name: "Engineering") }
  let(:space2) { create(:space, name: "DevOps") }
  let(:mapping) do
    mapping = create(:ldap_group_mapping, ldap_server: ldap_server, pattern_type: "exact", group_pattern: "cn=developers,ou=groups,dc=example,dc=com")
    mapping.spaces << space1
    mapping.spaces << space2
    mapping
  end

  let(:groups) { [ "cn=developers,ou=groups,dc=example,dc=com" ] }
  let(:service) { described_class.new(user, ldap_server, groups) }

  describe "#process" do
    context "when user has matching group memberships" do
      before { mapping } # Create the mapping

      it "subscribes user to mapped spaces" do
        result = service.process
        expect(result[:subscribed].map { |s| s[:space] }).to contain_exactly(space1, space2)
        expect(user.subscribed_spaces).to contain_exactly(space1, space2)
      end

      it "returns the mapping info for subscribed spaces" do
        result = service.process
        expect(result[:subscribed].first[:mapping]).to eq(mapping)
      end
    end

    context "when user is already subscribed to a space" do
      before do
        mapping
        user.space_subscriptions.create!(space: space1)
      end

      it "skips already subscribed spaces" do
        result = service.process
        expect(result[:skipped].map { |s| s[:space] }).to include(space1)
        expect(result[:skipped].find { |s| s[:space] == space1 }[:reason]).to eq(:already_subscribed)
      end

      it "still subscribes to other spaces" do
        result = service.process
        expect(result[:subscribed].map { |s| s[:space] }).to contain_exactly(space2)
      end
    end

    context "when user has opted out of a space" do
      before do
        mapping
        SpaceOptOut.create!(user: user, space: space1, ldap_group_mapping: mapping)
      end

      it "skips opted-out spaces" do
        result = service.process
        expect(result[:skipped].map { |s| s[:space] }).to include(space1)
        expect(result[:skipped].find { |s| s[:space] == space1 }[:reason]).to eq(:opted_out)
      end

      it "still subscribes to non-opted-out spaces" do
        result = service.process
        expect(result[:subscribed].map { |s| s[:space] }).to contain_exactly(space2)
      end
    end

    context "when groups do not match any mappings" do
      let(:groups) { [ "cn=admins,ou=groups,dc=example,dc=com" ] }

      before { mapping }

      it "does not subscribe user to any spaces" do
        result = service.process
        expect(result[:subscribed]).to be_empty
        expect(user.subscribed_spaces).to be_empty
      end
    end

    context "with prefix pattern matching" do
      let(:prefix_mapping) do
        m = create(:ldap_group_mapping, :prefix_match, ldap_server: ldap_server, group_pattern: "cn=dev")
        m.spaces << space1
        m
      end
      let(:groups) { [ "cn=developers,ou=groups,dc=example,dc=com" ] }

      before { prefix_mapping }

      it "matches groups by prefix" do
        result = service.process
        expect(result[:subscribed].map { |s| s[:space] }).to contain_exactly(space1)
      end
    end

    context "with suffix pattern matching" do
      let(:suffix_mapping) do
        m = create(:ldap_group_mapping, :suffix_match, ldap_server: ldap_server, group_pattern: "ou=engineering,dc=example,dc=com")
        m.spaces << space1
        m
      end
      let(:groups) { [ "cn=developers,ou=engineering,dc=example,dc=com" ] }

      before { suffix_mapping }

      it "matches groups by suffix" do
        result = service.process
        expect(result[:subscribed].map { |s| s[:space] }).to contain_exactly(space1)
      end
    end

    context "with contains pattern matching" do
      let(:contains_mapping) do
        m = create(:ldap_group_mapping, :contains_match, ldap_server: ldap_server, group_pattern: "developers")
        m.spaces << space1
        m
      end
      let(:groups) { [ "cn=senior-developers,ou=groups,dc=example,dc=com" ] }

      before { contains_mapping }

      it "matches groups containing pattern" do
        result = service.process
        expect(result[:subscribed].map { |s| s[:space] }).to contain_exactly(space1)
      end
    end

    context "with empty groups" do
      let(:groups) { [] }

      before { mapping }

      it "does not subscribe user to any spaces" do
        result = service.process
        expect(result[:subscribed]).to be_empty
      end
    end

    context "with nil groups" do
      let(:groups) { nil }

      before { mapping }

      it "handles nil groups gracefully" do
        result = service.process
        expect(result[:subscribed]).to be_empty
      end
    end
  end

  describe "#process!" do
    before { mapping }

    it "returns true" do
      expect(service.process!).to be true
    end

    it "subscribes user to mapped spaces" do
      service.process!
      expect(user.subscribed_spaces).to contain_exactly(space1, space2)
    end
  end
end
