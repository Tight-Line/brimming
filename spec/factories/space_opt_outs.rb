# frozen_string_literal: true

FactoryBot.define do
  factory :space_opt_out do
    user
    space
    ldap_group_mapping
  end
end
