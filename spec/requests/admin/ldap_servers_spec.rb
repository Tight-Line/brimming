# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::LdapServers", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:ldap_server) { create(:ldap_server) }

  describe "GET /admin/ldap_servers" do
    context "when not logged in" do
      it "redirects to root" do
        get admin_ldap_servers_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "redirects to root with alert" do
        get admin_ldap_servers_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You must be an admin to access this area.")
      end
    end

    context "when logged in as admin" do
      before { sign_in admin }

      it "returns http success" do
        get admin_ldap_servers_path
        expect(response).to have_http_status(:success)
      end

      it "displays LDAP servers" do
        ldap_server
        get admin_ldap_servers_path
        expect(response.body).to include(ldap_server.name)
      end
    end
  end

  describe "GET /admin/ldap_servers/:id" do
    before { sign_in admin }

    it "returns http success" do
      get admin_ldap_server_path(ldap_server)
      expect(response).to have_http_status(:success)
    end

    it "displays server details" do
      get admin_ldap_server_path(ldap_server)
      expect(response.body).to include(ldap_server.name)
      expect(response.body).to include(ldap_server.host)
    end
  end

  describe "GET /admin/ldap_servers/new" do
    before { sign_in admin }

    it "returns http success" do
      get new_admin_ldap_server_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/ldap_servers" do
    before { sign_in admin }

    let(:valid_params) do
      {
        ldap_server: {
          name: "New LDAP Server",
          host: "ldap.newserver.com",
          port: 389,
          encryption: "plain",
          user_search_base: "ou=users,dc=newserver,dc=com",
          uid_attribute: "uid",
          email_attribute: "mail"
        }
      }
    end

    it "creates a new LDAP server" do
      expect {
        post admin_ldap_servers_path, params: valid_params
      }.to change(LdapServer, :count).by(1)
    end

    it "redirects to the server show page" do
      post admin_ldap_servers_path, params: valid_params
      expect(response).to redirect_to(admin_ldap_server_path(LdapServer.last))
    end

    context "with invalid params" do
      let(:invalid_params) { { ldap_server: { name: "" } } }

      it "does not create a server" do
        expect {
          post admin_ldap_servers_path, params: invalid_params
        }.not_to change(LdapServer, :count)
      end

      it "renders the new form" do
        post admin_ldap_servers_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /admin/ldap_servers/:id/edit" do
    before { sign_in admin }

    it "returns http success" do
      get edit_admin_ldap_server_path(ldap_server)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/ldap_servers/:id" do
    before { sign_in admin }

    let(:update_params) do
      { ldap_server: { name: "Updated Name" } }
    end

    it "updates the LDAP server" do
      patch admin_ldap_server_path(ldap_server), params: update_params
      expect(ldap_server.reload.name).to eq("Updated Name")
    end

    it "redirects to the server show page" do
      patch admin_ldap_server_path(ldap_server), params: update_params
      expect(response).to redirect_to(admin_ldap_server_path(ldap_server))
    end

    context "with blank password" do
      it "preserves existing password" do
        original_password = ldap_server.bind_password
        patch admin_ldap_server_path(ldap_server), params: { ldap_server: { name: "New Name", bind_password: "" } }
        expect(ldap_server.reload.bind_password).to eq(original_password)
      end
    end

    context "with blank password when existing password is also blank" do
      let(:ldap_server_no_password) { create(:ldap_server, bind_password: nil) }

      it "allows update without changing password" do
        patch admin_ldap_server_path(ldap_server_no_password), params: { ldap_server: { name: "Updated Name", bind_password: "" } }
        expect(response).to redirect_to(admin_ldap_server_path(ldap_server_no_password))
        expect(ldap_server_no_password.reload.name).to eq("Updated Name")
        # Empty string is saved as-is when existing is nil (no preservation logic triggered)
        expect(ldap_server_no_password.bind_password).to eq("")
      end
    end

    context "with invalid params" do
      it "renders the edit form" do
        patch admin_ldap_server_path(ldap_server), params: { ldap_server: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /admin/ldap_servers/:id" do
    before { sign_in admin }

    it "deletes the LDAP server" do
      ldap_server # Create it first
      expect {
        delete admin_ldap_server_path(ldap_server)
      }.to change(LdapServer, :count).by(-1)
    end

    it "redirects to the index" do
      delete admin_ldap_server_path(ldap_server)
      expect(response).to redirect_to(admin_ldap_servers_path)
    end
  end
end
