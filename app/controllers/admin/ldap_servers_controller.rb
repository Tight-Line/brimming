# frozen_string_literal: true

module Admin
  class LdapServersController < BaseController
    before_action :set_ldap_server, only: [ :show, :edit, :update, :destroy ]

    def index
      @ldap_servers = LdapServer.order(:name)
    end

    def show
      @ldap_group_mappings = @ldap_server.ldap_group_mappings.includes(:spaces)
    end

    def new
      @ldap_server = LdapServer.new
    end

    def create
      @ldap_server = LdapServer.new(ldap_server_params)

      if @ldap_server.save
        redirect_to admin_ldap_server_path(@ldap_server),
                    notice: "LDAP server created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      update_params = ldap_server_params

      # Preserve existing password if field is left blank
      if update_params[:bind_password].blank? && @ldap_server.bind_password.present?
        update_params = update_params.except(:bind_password)
      end

      if @ldap_server.update(update_params)
        redirect_to admin_ldap_server_path(@ldap_server),
                    notice: "LDAP server updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @ldap_server.destroy!
      redirect_to admin_ldap_servers_path,
                  notice: "LDAP server deleted.", status: :see_other
    end

    private

    def set_ldap_server
      @ldap_server = LdapServer.find(params[:id])
    end

    def ldap_server_params
      params.require(:ldap_server).permit(
        :name, :host, :port, :encryption, :enabled,
        :bind_dn, :bind_password,
        :user_search_base, :user_search_filter,
        :group_search_base, :group_search_filter,
        :uid_attribute, :email_attribute, :name_attribute
      )
    end
  end
end
