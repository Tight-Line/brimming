# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::LdapGroupMappings", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:ldap_server) { create(:ldap_server) }
  let(:space) { create(:space) }
  let(:mapping) { create(:ldap_group_mapping, ldap_server: ldap_server) }

  before { sign_in admin }

  describe "GET /admin/ldap_servers/:ldap_server_id/ldap_group_mappings/new" do
    it "returns http success" do
      get new_admin_ldap_server_ldap_group_mapping_path(ldap_server)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/ldap_servers/:ldap_server_id/ldap_group_mappings" do
    let(:valid_params) do
      {
        ldap_group_mapping: {
          group_pattern: "cn=newgroup,ou=groups,dc=example,dc=com",
          pattern_type: "exact"
        }
      }
    end

    it "creates a new mapping" do
      expect {
        post admin_ldap_server_ldap_group_mappings_path(ldap_server), params: valid_params
      }.to change(LdapGroupMapping, :count).by(1)
    end

    it "redirects to the mapping show page" do
      post admin_ldap_server_ldap_group_mappings_path(ldap_server), params: valid_params
      expect(response).to redirect_to(admin_ldap_server_ldap_group_mapping_path(ldap_server, LdapGroupMapping.last))
    end

    context "with invalid params" do
      let(:invalid_params) { { ldap_group_mapping: { group_pattern: "" } } }

      it "does not create a mapping" do
        expect {
          post admin_ldap_server_ldap_group_mappings_path(ldap_server), params: invalid_params
        }.not_to change(LdapGroupMapping, :count)
      end

      it "renders the new form" do
        post admin_ldap_server_ldap_group_mappings_path(ldap_server), params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /admin/ldap_servers/:ldap_server_id/ldap_group_mappings/:id" do
    it "returns http success" do
      get admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/ldap_servers/:ldap_server_id/ldap_group_mappings/:id/edit" do
    it "returns http success" do
      get edit_admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/ldap_servers/:ldap_server_id/ldap_group_mappings/:id" do
    let(:update_params) do
      { ldap_group_mapping: { group_pattern: "cn=updated,ou=groups,dc=example,dc=com" } }
    end

    it "updates the mapping" do
      patch admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping), params: update_params
      expect(mapping.reload.group_pattern).to eq("cn=updated,ou=groups,dc=example,dc=com")
    end

    it "redirects to the mapping show page" do
      patch admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping), params: update_params
      expect(response).to redirect_to(admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping))
    end

    context "with invalid params" do
      let(:invalid_params) { { ldap_group_mapping: { group_pattern: "" } } }

      it "does not update the mapping" do
        original_pattern = mapping.group_pattern
        patch admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping), params: invalid_params
        expect(mapping.reload.group_pattern).to eq(original_pattern)
      end

      it "renders the edit form" do
        patch admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping), params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /admin/ldap_servers/:ldap_server_id/ldap_group_mappings/:id" do
    it "deletes the mapping" do
      mapping # Create it first
      expect {
        delete admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping)
      }.to change(LdapGroupMapping, :count).by(-1)
    end

    it "redirects to the server show page" do
      delete admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping)
      expect(response).to redirect_to(admin_ldap_server_path(ldap_server))
    end
  end

  describe "POST /admin/ldap_servers/:ldap_server_id/ldap_group_mappings/:id/add_space" do
    it "adds a space to the mapping" do
      expect {
        post add_space_admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping), params: { space_id: space.id }
      }.to change { mapping.spaces.count }.by(1)
    end

    it "redirects to the mapping show page" do
      post add_space_admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping), params: { space_id: space.id }
      expect(response).to redirect_to(admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping))
    end

    context "when space is already added" do
      before { mapping.spaces << space }

      it "does not add duplicate" do
        expect {
          post add_space_admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping), params: { space_id: space.id }
        }.not_to change { mapping.spaces.count }
      end
    end
  end

  describe "DELETE /admin/ldap_servers/:ldap_server_id/ldap_group_mappings/:id/remove_space" do
    before { mapping.spaces << space }

    it "removes the space from the mapping" do
      expect {
        delete remove_space_admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping), params: { space_id: space.id }
      }.to change { mapping.spaces.count }.by(-1)
    end

    it "redirects to the mapping show page" do
      delete remove_space_admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping), params: { space_id: space.id }
      expect(response).to redirect_to(admin_ldap_server_ldap_group_mapping_path(ldap_server, mapping))
    end
  end
end
