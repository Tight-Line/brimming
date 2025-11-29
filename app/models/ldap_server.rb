# frozen_string_literal: true

class LdapServer < ApplicationRecord
  # Encryption options
  ENCRYPTION_OPTIONS = %w[plain start_tls simple_tls].freeze

  # Associations
  has_many :ldap_group_mappings, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :host, presence: true
  validates :port, presence: true, numericality: { only_integer: true, greater_than: 0, less_than: 65_536 }
  validates :encryption, presence: true, inclusion: { in: ENCRYPTION_OPTIONS }
  validates :user_search_base, presence: true
  validates :uid_attribute, presence: true
  validates :email_attribute, presence: true

  # Scopes
  scope :enabled, -> { where(enabled: true) }

  # Returns the encryption method as a symbol for net-ldap
  def encryption_method
    case encryption
    when "start_tls"
      :start_tls
    when "simple_tls"
      :simple_tls
    else
      nil
    end
  end

  # Build net-ldap connection options
  def connection_options
    opts = {
      host: host,
      port: port,
      base: user_search_base
    }

    opts[:encryption] = { method: encryption_method } if encryption_method

    if bind_dn.present? && bind_password.present?
      opts[:auth] = {
        method: :simple,
        username: bind_dn,
        password: bind_password
      }
    end

    opts
  end

  # Build OmniAuth LDAP configuration hash
  def omniauth_config
    {
      host: host,
      port: port,
      method: encryption.to_sym,
      base: user_search_base,
      uid: uid_attribute,
      bind_dn: bind_dn,
      password: bind_password,
      filter: user_search_filter,
      name_proc: ->(name) { name }
    }.compact
  end
end
