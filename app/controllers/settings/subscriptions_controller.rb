# frozen_string_literal: true

module Settings
  class SubscriptionsController < ApplicationController
    before_action :authenticate_user!

    def index
      @subscriptions = build_subscription_list
    end

    private

    # Build a unified list of all subscriptions (manual + LDAP)
    # Returns array of hashes with :space, :source, :ldap_group_name, :opted_out, :subscribed
    def build_subscription_list
      subscriptions = []

      # Add manual subscriptions
      current_user.space_subscriptions.includes(:space).each do |subscription|
        subscriptions << {
          space: subscription.space,
          source: :manual,
          ldap_group_name: nil,
          opted_out: false,
          subscribed: true,
          subscription: subscription
        }
      end

      # Add LDAP-based subscriptions if user is an LDAP user
      if current_user.ldap_user?
        ldap_subscriptions = ldap_assigned_spaces
        ldap_subscriptions.each do |ldap_sub|
          # Skip if already in manual subscriptions
          next if subscriptions.any? { |s| s[:space].id == ldap_sub[:space].id }

          subscriptions << ldap_sub
        end
      end

      # Sort by space name
      subscriptions.sort_by { |s| s[:space].name.downcase }
    end

    def ldap_assigned_spaces
      return [] unless current_user.ldap_dn.present?

      ldap_server = LdapServer.enabled.find_by(id: session[:ldap_server_id])
      return [] unless ldap_server

      results = []
      ldap_server.ldap_group_mappings.includes(:spaces).each do |mapping|
        mapping.spaces.each do |space|
          opted_out = current_user.space_opt_outs.exists?(
            space: space,
            ldap_group_mapping: mapping
          )
          results << {
            space: space,
            source: :ldap,
            ldap_group_name: mapping.group_pattern,
            opted_out: opted_out,
            subscribed: !opted_out && current_user.subscribed_spaces.include?(space),
            mapping: mapping
          }
        end
      end
      results
    end
  end
end
