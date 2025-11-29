# frozen_string_literal: true

FactoryBot.define do
  factory :ldap_server do
    sequence(:name) { |n| "LDAP Server #{n}" }
    host { "ldap.example.com" }
    port { 389 }
    encryption { "plain" }
    bind_dn { "cn=admin,dc=example,dc=com" }
    bind_password { "secret" }
    user_search_base { "ou=users,dc=example,dc=com" }
    user_search_filter { "(uid=%{username})" }
    group_search_base { "ou=groups,dc=example,dc=com" }
    group_search_filter { "(member=%{dn})" }
    uid_attribute { "uid" }
    email_attribute { "mail" }
    name_attribute { "cn" }
    enabled { true }

    trait :disabled do
      enabled { false }
    end

    trait :with_tls do
      encryption { "start_tls" }
    end

    trait :with_ssl do
      encryption { "simple_tls" }
      port { 636 }
    end

    trait :active_directory do
      user_search_filter { "(sAMAccountName=%{username})" }
      uid_attribute { "sAMAccountName" }
    end
  end
end
