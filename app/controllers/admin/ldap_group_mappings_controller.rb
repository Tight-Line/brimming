# frozen_string_literal: true

module Admin
  class LdapGroupMappingsController < BaseController
    before_action :set_ldap_server
    before_action :set_ldap_group_mapping, only: [ :show, :edit, :update, :destroy, :add_space, :remove_space ]

    def show
      @spaces = Space.order(:name)
      @mapped_spaces = @ldap_group_mapping.spaces
    end

    def new
      @ldap_group_mapping = @ldap_server.ldap_group_mappings.build
    end

    def create
      @ldap_group_mapping = @ldap_server.ldap_group_mappings.build(ldap_group_mapping_params)

      if @ldap_group_mapping.save
        redirect_to admin_ldap_server_ldap_group_mapping_path(@ldap_server, @ldap_group_mapping),
                    notice: "Group mapping created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @ldap_group_mapping.update(ldap_group_mapping_params)
        redirect_to admin_ldap_server_ldap_group_mapping_path(@ldap_server, @ldap_group_mapping),
                    notice: "Group mapping updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @ldap_group_mapping.destroy!
      redirect_to admin_ldap_server_path(@ldap_server),
                  notice: "Group mapping deleted.", status: :see_other
    end

    def add_space
      space = Space.find(params[:space_id])

      if @ldap_group_mapping.spaces.include?(space)
        flash[:alert] = "Space is already mapped."
      else
        @ldap_group_mapping.spaces << space
        flash[:notice] = "Space added to mapping."
      end

      redirect_to admin_ldap_server_ldap_group_mapping_path(@ldap_server, @ldap_group_mapping)
    end

    def remove_space
      space = Space.find(params[:space_id])
      @ldap_group_mapping.spaces.delete(space)

      redirect_to admin_ldap_server_ldap_group_mapping_path(@ldap_server, @ldap_group_mapping),
                  notice: "Space removed from mapping.", status: :see_other
    end

    private

    def set_ldap_server
      @ldap_server = LdapServer.find(params[:ldap_server_id])
    end

    def set_ldap_group_mapping
      @ldap_group_mapping = @ldap_server.ldap_group_mappings.find(params[:id])
    end

    def ldap_group_mapping_params
      params.require(:ldap_group_mapping).permit(:group_pattern, :pattern_type)
    end
  end
end
