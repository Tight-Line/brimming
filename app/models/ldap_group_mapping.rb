# frozen_string_literal: true

class LdapGroupMapping < ApplicationRecord
  # Pattern matching types
  PATTERN_TYPES = %w[exact prefix suffix contains].freeze

  # Associations
  belongs_to :ldap_server
  has_many :ldap_group_mapping_spaces, dependent: :destroy
  has_many :spaces, through: :ldap_group_mapping_spaces
  has_many :space_opt_outs, dependent: :destroy

  # Validations
  validates :group_pattern, presence: true, uniqueness: { scope: :ldap_server_id }
  validates :pattern_type, presence: true, inclusion: { in: PATTERN_TYPES }

  # Check if a group DN or name matches this mapping's pattern
  def matches?(group_dn)
    return false if group_dn.blank?

    case pattern_type
    when "exact"
      group_dn.casecmp?(group_pattern)
    when "prefix"
      group_dn.downcase.start_with?(group_pattern.downcase)
    when "suffix"
      group_dn.downcase.end_with?(group_pattern.downcase)
    when "contains"
      group_dn.downcase.include?(group_pattern.downcase)
    else
      false
    end
  end

  # Get spaces for a user, excluding opted-out ones
  def spaces_for_user(user)
    opted_out_space_ids = space_opt_outs.where(user: user).pluck(:space_id)
    spaces.where.not(id: opted_out_space_ids)
  end
end
