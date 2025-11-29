# frozen_string_literal: true

# Service for auto-registering users into spaces based on their LDAP group memberships
class LdapSpaceRegistrationService
  attr_reader :user, :ldap_server, :groups

  def initialize(user, ldap_server, groups)
    @user = user
    @ldap_server = ldap_server
    @groups = groups || []
  end

  # Process group memberships and register user to matching spaces
  # Returns a hash with :subscribed and :skipped arrays
  def process
    result = { subscribed: [], skipped: [] }

    ldap_server.ldap_group_mappings.includes(:spaces).find_each do |mapping|
      matching_groups = groups.select { |group| mapping.matches?(group) }
      next if matching_groups.empty?

      mapping.spaces.each do |space|
        if opted_out?(mapping, space)
          result[:skipped] << { space: space, mapping: mapping, reason: :opted_out }
        elsif already_subscribed?(space)
          result[:skipped] << { space: space, mapping: mapping, reason: :already_subscribed }
        else
          subscribe_to_space(space)
          result[:subscribed] << { space: space, mapping: mapping }
        end
      end
    end

    result
  end

  # Register user to all matching spaces without returning details
  def process!
    process
    true
  end

  private

  def opted_out?(mapping, space)
    user.space_opt_outs.exists?(space: space, ldap_group_mapping: mapping)
  end

  def already_subscribed?(space)
    user.subscribed_spaces.include?(space)
  end

  def subscribe_to_space(space)
    user.space_subscriptions.find_or_create_by!(space: space)
  end
end
