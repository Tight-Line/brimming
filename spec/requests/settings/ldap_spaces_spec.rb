# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::LdapSpaces", type: :request do
  let(:ldap_user) { create(:user, provider: "ldap", uid: "testuser", ldap_dn: "uid=testuser,ou=users,dc=example,dc=com") }
  let(:regular_user) { create(:user) }
  let(:ldap_server) { create(:ldap_server) }
  let(:space) { create(:space) }
  let(:mapping) do
    m = create(:ldap_group_mapping, ldap_server: ldap_server)
    m.spaces << space
    m
  end

  describe "GET /settings/ldap_spaces" do
    context "when not logged in" do
      it "redirects to login" do
        get settings_ldap_spaces_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "redirects to root" do
        get settings_ldap_spaces_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("This feature is only available for LDAP users")
      end
    end

    context "when logged in as LDAP user" do
      before do
        sign_in ldap_user
        # Simulate session containing LDAP server ID
        allow_any_instance_of(Settings::LdapSpacesController).to receive(:session).and_return({ ldap_server_id: ldap_server.id })
      end

      it "returns http success" do
        get settings_ldap_spaces_path
        expect(response).to have_http_status(:success)
      end

      it "displays LDAP space assignments" do
        mapping # Create the mapping
        get settings_ldap_spaces_path
        expect(response.body).to include("LDAP Space Assignments")
      end
    end
  end

  describe "POST /settings/ldap_spaces/opt_out" do
    before do
      sign_in ldap_user
      mapping # Create the mapping
    end

    it "creates an opt-out record" do
      expect {
        post opt_out_settings_ldap_spaces_path, params: { mapping_id: mapping.id, space_id: space.id }
      }.to change(SpaceOptOut, :count).by(1)
    end

    it "redirects back with notice" do
      post opt_out_settings_ldap_spaces_path, params: { mapping_id: mapping.id, space_id: space.id }
      expect(response).to redirect_to(settings_ldap_spaces_path)
      expect(flash[:notice]).to include("opted out")
    end
  end

  describe "POST /settings/ldap_spaces/opt_in" do
    before do
      sign_in ldap_user
      mapping
      SpaceOptOut.create!(user: ldap_user, space: space, ldap_group_mapping: mapping)
    end

    it "removes the opt-out record" do
      expect {
        post opt_in_settings_ldap_spaces_path, params: { mapping_id: mapping.id, space_id: space.id }
      }.to change(SpaceOptOut, :count).by(-1)
    end

    it "redirects back with notice" do
      post opt_in_settings_ldap_spaces_path, params: { mapping_id: mapping.id, space_id: space.id }
      expect(response).to redirect_to(settings_ldap_spaces_path)
      expect(flash[:notice]).to include("opted back into")
    end

    context "when opt-out record doesn't exist" do
      before do
        SpaceOptOut.destroy_all
      end

      it "handles gracefully when no opt-out to remove" do
        expect {
          post opt_in_settings_ldap_spaces_path, params: { mapping_id: mapping.id, space_id: space.id }
        }.not_to change(SpaceOptOut, :count)
        expect(response).to redirect_to(settings_ldap_spaces_path)
      end
    end
  end

  describe "GET /settings/ldap_spaces edge cases" do
    before do
      sign_in ldap_user
      allow_any_instance_of(Settings::LdapSpacesController).to receive(:session).and_return({ ldap_server_id: ldap_server.id })
    end

    context "when user has no ldap_dn" do
      let(:ldap_user_no_dn) { create(:user, provider: "ldap", uid: "nodn_user", ldap_dn: nil) }

      before { sign_in ldap_user_no_dn }

      it "returns empty mappings" do
        get settings_ldap_spaces_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when ldap_server is not found" do
      before do
        allow_any_instance_of(Settings::LdapSpacesController).to receive(:session).and_return({ ldap_server_id: 99999 })
      end

      it "returns empty mappings" do
        get settings_ldap_spaces_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "invalid mapping/space" do
    before { sign_in ldap_user }

    it "redirects with alert when mapping not found" do
      post opt_out_settings_ldap_spaces_path, params: { mapping_id: 99999, space_id: space.id }
      expect(response).to redirect_to(settings_ldap_spaces_path)
      expect(flash[:alert]).to eq("Space mapping not found")
    end

    it "redirects with alert when space not in mapping" do
      other_space = create(:space)
      post opt_out_settings_ldap_spaces_path, params: { mapping_id: mapping.id, space_id: other_space.id }
      expect(response).to redirect_to(settings_ldap_spaces_path)
      expect(flash[:alert]).to eq("Space mapping not found")
    end
  end
end
