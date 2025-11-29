# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpaceOptOut, type: :model do
  describe "validations" do
    subject { build(:space_opt_out) }

    it { should validate_uniqueness_of(:space_id).scoped_to([ :user_id, :ldap_group_mapping_id ]) }
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:space) }
    it { should belong_to(:ldap_group_mapping) }
  end

  describe "creating opt-outs" do
    let(:user) { create(:user) }
    let(:space) { create(:space) }
    let(:ldap_server) { create(:ldap_server) }
    let(:mapping) { create(:ldap_group_mapping, ldap_server: ldap_server) }

    it "allows creating an opt-out for a user, space, and mapping" do
      opt_out = SpaceOptOut.create!(user: user, space: space, ldap_group_mapping: mapping)
      expect(opt_out).to be_persisted
    end

    it "prevents duplicate opt-outs" do
      SpaceOptOut.create!(user: user, space: space, ldap_group_mapping: mapping)
      duplicate = SpaceOptOut.new(user: user, space: space, ldap_group_mapping: mapping)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:space_id]).to include("has already been taken")
    end

    it "allows same user and space with different mappings" do
      mapping2 = create(:ldap_group_mapping, ldap_server: ldap_server, group_pattern: "cn=admins")
      SpaceOptOut.create!(user: user, space: space, ldap_group_mapping: mapping)
      opt_out2 = SpaceOptOut.create(user: user, space: space, ldap_group_mapping: mapping2)
      expect(opt_out2).to be_persisted
    end
  end
end
