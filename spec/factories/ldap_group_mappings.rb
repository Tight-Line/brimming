# frozen_string_literal: true

FactoryBot.define do
  factory :ldap_group_mapping do
    ldap_server
    group_pattern { "cn=developers,ou=groups,dc=example,dc=com" }
    pattern_type { "exact" }

    trait :prefix_match do
      pattern_type { "prefix" }
      group_pattern { "cn=dev" }
    end

    trait :suffix_match do
      pattern_type { "suffix" }
      group_pattern { "ou=engineering,dc=example,dc=com" }
    end

    trait :contains_match do
      pattern_type { "contains" }
      group_pattern { "developers" }
    end
  end
end
