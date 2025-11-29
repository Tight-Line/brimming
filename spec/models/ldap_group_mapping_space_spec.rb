# frozen_string_literal: true

require "rails_helper"

RSpec.describe LdapGroupMappingSpace, type: :model do
  describe "validations" do
    subject { build(:ldap_group_mapping_space) }

    it { should validate_uniqueness_of(:space_id).scoped_to(:ldap_group_mapping_id) }
  end

  describe "associations" do
    it { should belong_to(:ldap_group_mapping) }
    it { should belong_to(:space) }
  end
end
