# frozen_string_literal: true

class SpaceOptOut < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :space
  belongs_to :ldap_group_mapping

  # Validations
  validates :space_id, uniqueness: { scope: [ :user_id, :ldap_group_mapping_id ] }
end
