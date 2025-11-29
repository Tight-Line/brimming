# frozen_string_literal: true

module Settings
  class LdapSpacesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_ldap_user
    before_action :set_mapping_space, only: [ :opt_out, :opt_in ]

    def index
      @ldap_mappings = current_user_ldap_mappings
    end

    def opt_out
      SpaceOptOut.find_or_create_by!(
        user: current_user,
        space: @space,
        ldap_group_mapping: @mapping
      )

      respond_to do |format|
        format.html do
          redirect_to settings_ldap_spaces_path,
                      notice: "You have opted out of '#{@space.name}'"
        end
        format.turbo_stream
      end
    end

    def opt_in
      opt_out = SpaceOptOut.find_by(
        user: current_user,
        space: @space,
        ldap_group_mapping: @mapping
      )
      opt_out&.destroy

      respond_to do |format|
        format.html do
          redirect_to settings_ldap_spaces_path,
                      notice: "You have opted back into '#{@space.name}'"
        end
        format.turbo_stream
      end
    end

    private

    def require_ldap_user
      unless current_user.ldap_user?
        redirect_to root_path, alert: "This feature is only available for LDAP users"
      end
    end

    def set_mapping_space
      @mapping = LdapGroupMapping.find(params[:mapping_id])
      @space = @mapping.spaces.find(params[:space_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to settings_ldap_spaces_path, alert: "Space mapping not found"
    end

    # Find all LDAP group mappings that apply to the current user
    # This returns mappings from the server they authenticated with
    def current_user_ldap_mappings
      return [] unless current_user.ldap_dn.present?

      # Find the LDAP server the user authenticated with
      ldap_server = LdapServer.enabled.find_by(id: ldap_server_id_from_session)
      return [] unless ldap_server

      # Get all mappings with their spaces, organized by mapping
      ldap_server.ldap_group_mappings.includes(:spaces).map do |mapping|
        {
          mapping: mapping,
          spaces: mapping.spaces.map do |space|
            opted_out = current_user.space_opt_outs.exists?(
              space: space,
              ldap_group_mapping: mapping
            )
            subscribed = current_user.subscribed_spaces.include?(space)
            {
              space: space,
              opted_out: opted_out,
              subscribed: subscribed
            }
          end
        }
      end.select { |m| m[:spaces].any? }
    end

    def ldap_server_id_from_session
      # The LDAP server ID should be stored in session during login
      session[:ldap_server_id]
    end
  end
end
