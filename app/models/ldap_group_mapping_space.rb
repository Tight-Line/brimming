# frozen_string_literal: true

class LdapGroupMappingSpace < ApplicationRecord
  # Associations
  belongs_to :ldap_group_mapping
  belongs_to :space

  # Validations
  validates :space_id, uniqueness: { scope: :ldap_group_mapping_id }
end
