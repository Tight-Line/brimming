# frozen_string_literal: true

require "rails_helper"

RSpec.describe LdapGroupMapping, type: :model do
  describe "validations" do
    subject { build(:ldap_group_mapping) }

    it { should validate_presence_of(:group_pattern) }
    it { should validate_presence_of(:pattern_type) }
    it { should validate_inclusion_of(:pattern_type).in_array(LdapGroupMapping::PATTERN_TYPES) }
  end

  describe "associations" do
    it { should belong_to(:ldap_server) }
    it { should have_many(:ldap_group_mapping_spaces).dependent(:destroy) }
    it { should have_many(:spaces).through(:ldap_group_mapping_spaces) }
    it { should have_many(:space_opt_outs).dependent(:destroy) }
  end

  describe "#matches?" do
    let(:ldap_server) { create(:ldap_server) }

    context "with blank group_dn" do
      let(:mapping) { create(:ldap_group_mapping, ldap_server: ldap_server, pattern_type: "exact", group_pattern: "cn=test") }

      it "returns false for nil group_dn" do
        expect(mapping.matches?(nil)).to be false
      end

      it "returns false for empty group_dn" do
        expect(mapping.matches?("")).to be false
      end
    end

    context "with exact pattern type" do
      let(:mapping) { create(:ldap_group_mapping, ldap_server: ldap_server, pattern_type: "exact", group_pattern: "cn=developers,ou=groups,dc=example,dc=com") }

      it "matches exact group DN (case insensitive)" do
        expect(mapping.matches?("cn=developers,ou=groups,dc=example,dc=com")).to be true
        expect(mapping.matches?("CN=DEVELOPERS,OU=GROUPS,DC=EXAMPLE,DC=COM")).to be true
      end

      it "does not match different group DN" do
        expect(mapping.matches?("cn=admins,ou=groups,dc=example,dc=com")).to be false
      end
    end

    context "with prefix pattern type" do
      let(:mapping) { create(:ldap_group_mapping, :prefix_match, ldap_server: ldap_server, group_pattern: "cn=dev") }

      it "matches groups starting with pattern" do
        expect(mapping.matches?("cn=developers,ou=groups,dc=example,dc=com")).to be true
        expect(mapping.matches?("cn=devops,ou=groups,dc=example,dc=com")).to be true
      end

      it "does not match groups not starting with pattern" do
        expect(mapping.matches?("cn=admins,ou=groups,dc=example,dc=com")).to be false
      end
    end

    context "with suffix pattern type" do
      let(:mapping) { create(:ldap_group_mapping, :suffix_match, ldap_server: ldap_server, group_pattern: "ou=engineering,dc=example,dc=com") }

      it "matches groups ending with pattern" do
        expect(mapping.matches?("cn=developers,ou=engineering,dc=example,dc=com")).to be true
      end

      it "does not match groups not ending with pattern" do
        expect(mapping.matches?("cn=developers,ou=sales,dc=example,dc=com")).to be false
      end
    end

    context "with contains pattern type" do
      let(:mapping) { create(:ldap_group_mapping, :contains_match, ldap_server: ldap_server, group_pattern: "developers") }

      it "matches groups containing pattern" do
        expect(mapping.matches?("cn=developers,ou=groups,dc=example,dc=com")).to be true
        expect(mapping.matches?("cn=senior-developers,ou=groups,dc=example,dc=com")).to be true
      end

      it "does not match groups not containing pattern" do
        expect(mapping.matches?("cn=admins,ou=groups,dc=example,dc=com")).to be false
      end
    end

    context "with unknown pattern type" do
      let(:mapping) { build(:ldap_group_mapping, ldap_server: ldap_server) }

      it "returns false" do
        mapping.pattern_type = "unknown"
        expect(mapping.matches?("cn=developers,ou=groups,dc=example,dc=com")).to be false
      end
    end
  end

  describe "#spaces_for_user" do
    let(:ldap_server) { create(:ldap_server) }
    let(:mapping) { create(:ldap_group_mapping, ldap_server: ldap_server) }
    let(:user) { create(:user) }
    let(:space1) { create(:space) }
    let(:space2) { create(:space) }
    let(:space3) { create(:space) }

    before do
      mapping.spaces << [ space1, space2, space3 ]
    end

    it "returns all spaces when user has no opt-outs" do
      result = mapping.spaces_for_user(user)
      expect(result).to contain_exactly(space1, space2, space3)
    end

    it "excludes spaces the user has opted out of" do
      create(:space_opt_out, user: user, space: space2, ldap_group_mapping: mapping)
      result = mapping.spaces_for_user(user)
      expect(result).to contain_exactly(space1, space3)
    end

    it "excludes multiple opted-out spaces" do
      create(:space_opt_out, user: user, space: space1, ldap_group_mapping: mapping)
      create(:space_opt_out, user: user, space: space3, ldap_group_mapping: mapping)
      result = mapping.spaces_for_user(user)
      expect(result).to contain_exactly(space2)
    end

    it "returns empty array when user has opted out of all spaces" do
      create(:space_opt_out, user: user, space: space1, ldap_group_mapping: mapping)
      create(:space_opt_out, user: user, space: space2, ldap_group_mapping: mapping)
      create(:space_opt_out, user: user, space: space3, ldap_group_mapping: mapping)
      result = mapping.spaces_for_user(user)
      expect(result).to be_empty
    end
  end
end
