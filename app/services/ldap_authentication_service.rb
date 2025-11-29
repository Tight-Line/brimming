# frozen_string_literal: true

# Service for authenticating users against LDAP servers and fetching their group memberships
class LdapAuthenticationService
  attr_reader :ldap_server, :username, :password

  def initialize(ldap_server, username, password)
    @ldap_server = ldap_server
    @username = username
    @password = password
  end

  # Authenticate user and return user entry if successful, nil otherwise
  def authenticate
    Rails.logger.info("[LDAP] Authenticating user '#{username}' against server '#{ldap_server.name}'")

    unless ldap_server.enabled?
      Rails.logger.warn("[LDAP] Server '#{ldap_server.name}' is disabled")
      return nil
    end

    ldap = build_connection
    Rails.logger.debug("[LDAP] Connection options: #{ldap_server.connection_options.except(:auth).inspect}")

    user_entry = find_user(ldap)
    unless user_entry
      Rails.logger.warn("[LDAP] User '#{username}' not found in directory")
      return nil
    end

    Rails.logger.info("[LDAP] Found user DN: #{user_entry.dn}")

    # Attempt to bind as the user to verify password
    if verify_password(user_entry.dn, password)
      Rails.logger.info("[LDAP] Authentication successful for '#{username}'")
      user_entry
    else
      Rails.logger.warn("[LDAP] Password verification failed for '#{username}'")
      nil
    end
  end

  # Fetch group DNs for a given user DN
  def fetch_groups(user_dn)
    return [] if ldap_server.group_search_base.blank?

    ldap = build_connection
    bind_for_search(ldap)

    filter_str = ldap_server.group_search_filter.gsub("%{dn}", user_dn)
    filter = Net::LDAP::Filter.construct(filter_str)

    groups = []
    ldap.search(base: ldap_server.group_search_base, filter: filter) do |entry|
      groups << entry.dn
    end

    groups
  rescue Net::LDAP::Error => e
    Rails.logger.error("LDAP group search failed: #{e.message}")
    []
  end

  # Build auth hash similar to OmniAuth format
  # Note: Net::LDAP::Entry always returns arrays for attribute access (empty array if missing),
  # so we use .first directly without safe navigation.
  def build_auth_hash(user_entry, groups)
    {
      provider: "ldap",
      uid: user_entry[ldap_server.uid_attribute].first,
      info: {
        email: user_entry[ldap_server.email_attribute].first,
        name: user_entry[ldap_server.name_attribute].first,
        nickname: user_entry[ldap_server.uid_attribute].first
      },
      extra: {
        raw_info: {
          dn: user_entry.dn,
          groups: groups
        }
      }
    }
  end

  private

  def build_connection
    Net::LDAP.new(ldap_server.connection_options)
  end

  def bind_for_search(ldap)
    if ldap_server.bind_dn.present? && ldap_server.bind_password.present?
      Rails.logger.debug("[LDAP] Binding with service account: #{ldap_server.bind_dn}")
      ldap.auth(ldap_server.bind_dn, ldap_server.bind_password)
      result = ldap.bind
      Rails.logger.debug("[LDAP] Service account bind result: #{result.inspect}, operation: #{ldap.get_operation_result.inspect}")
      result
    else
      Rails.logger.warn("[LDAP] No bind credentials configured (bind_dn: #{ldap_server.bind_dn.present?}, bind_password: #{ldap_server.bind_password.present?})")
      nil
    end
  end

  def find_user(ldap)
    bind_result = bind_for_search(ldap)
    Rails.logger.debug("[LDAP] Bind for search result: #{bind_result.inspect}, operation_result: #{ldap.get_operation_result.inspect}")

    filter_str = ldap_server.user_search_filter.gsub("%{username}", escape_ldap(username))
    Rails.logger.debug("[LDAP] Searching with filter: #{filter_str} in base: #{ldap_server.user_search_base}")

    filter = Net::LDAP::Filter.construct(filter_str)

    result = nil
    ldap.search(base: ldap_server.user_search_base, filter: filter) do |entry|
      Rails.logger.debug("[LDAP] Found entry: #{entry.dn}")
      result = entry
      break
    end

    unless result
      Rails.logger.debug("[LDAP] Search operation result: #{ldap.get_operation_result.inspect}")
    end

    result
  rescue Net::LDAP::Error => e
    Rails.logger.error("[LDAP] User search failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    nil
  end

  def verify_password(user_dn, password)
    return false if password.blank?

    ldap = build_connection
    ldap.auth(user_dn, password)
    ldap.bind
  rescue Net::LDAP::Error => e
    Rails.logger.error("LDAP bind failed: #{e.message}")
    false
  end

  def escape_ldap(str)
    # Escape special LDAP characters
    str.to_s.gsub(/([,\\#+<>;"=])/) { |m| "\\#{m}" }
  end
end
