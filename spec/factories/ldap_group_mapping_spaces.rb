# frozen_string_literal: true

FactoryBot.define do
  factory :ldap_group_mapping_space do
    ldap_group_mapping
    space
  end
end
