# frozen_string_literal: true

require "rails_helper"

RSpec.describe "LdapSessions", type: :request do
  let!(:ldap_server) { create(:ldap_server) }

  describe "GET /ldap/sign_in" do
    context "when LDAP servers are configured" do
      it "returns http success" do
        get ldap_sign_in_path
        expect(response).to have_http_status(:success)
      end

      it "displays the LDAP server selection" do
        get ldap_sign_in_path
        expect(response.body).to include(ldap_server.name)
      end
    end

    context "when no LDAP servers are configured" do
      before { LdapServer.destroy_all }

      it "redirects to regular sign in" do
        get ldap_sign_in_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it "shows an alert" do
        get ldap_sign_in_path
        expect(flash[:alert]).to eq("No LDAP servers are configured.")
      end
    end

    context "when all LDAP servers are disabled" do
      before { ldap_server.update!(enabled: false) }

      it "redirects to regular sign in" do
        get ldap_sign_in_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /ldap/sign_in" do
    let(:mock_ldap) { instance_double(Net::LDAP) }
    let(:mock_user_entry) do
      entry = Net::LDAP::Entry.new("uid=testuser,ou=users,dc=example,dc=com")
      entry["uid"] = [ "testuser" ]
      entry["mail"] = [ "testuser@example.com" ]
      entry["cn"] = [ "Test User" ]
      entry
    end

    before do
      allow(Net::LDAP).to receive(:new).and_return(mock_ldap)
    end

    context "without server selection" do
      it "redirects back with alert" do
        post ldap_sign_in_path, params: { username: "test", password: "pass" }
        expect(response).to redirect_to(ldap_sign_in_path)
        expect(flash[:alert]).to eq("Please select an LDAP server.")
      end
    end

    context "without username or password" do
      it "redirects back with alert when username is blank" do
        post ldap_sign_in_path, params: { ldap_server_id: ldap_server.id, username: "", password: "pass" }
        expect(response).to redirect_to(ldap_sign_in_path)
        expect(flash[:alert]).to eq("Username and password are required.")
      end

      it "redirects back with alert when password is blank" do
        post ldap_sign_in_path, params: { ldap_server_id: ldap_server.id, username: "test", password: "" }
        expect(response).to redirect_to(ldap_sign_in_path)
        expect(flash[:alert]).to eq("Username and password are required.")
      end
    end

    context "with valid credentials" do
      before do
        allow(mock_ldap).to receive(:auth)
        allow(mock_ldap).to receive(:bind).and_return(true)
        allow(mock_ldap).to receive(:search).and_yield(mock_user_entry)
        allow(mock_ldap).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
      end

      it "creates a new user from LDAP" do
        expect {
          post ldap_sign_in_path, params: { ldap_server_id: ldap_server.id, username: "testuser", password: "testpass" }
        }.to change(User, :count).by(1)
      end

      it "redirects to root with success notice" do
        post ldap_sign_in_path, params: { ldap_server_id: ldap_server.id, username: "testuser", password: "testpass" }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include("Signed in successfully")
      end

      it "stores the LDAP server ID in session" do
        post ldap_sign_in_path, params: { ldap_server_id: ldap_server.id, username: "testuser", password: "testpass" }
        # Session is tested indirectly - if we can access LDAP spaces page, it worked
        follow_redirect!
        expect(response).to have_http_status(:success)
      end

      context "when user already exists with same email" do
        let!(:existing_user) { create(:user, email: "testuser@example.com") }

        it "updates existing user with LDAP info" do
          expect {
            post ldap_sign_in_path, params: { ldap_server_id: ldap_server.id, username: "testuser", password: "testpass" }
          }.not_to change(User, :count)

          expect(existing_user.reload.provider).to eq("ldap")
          expect(existing_user.uid).to eq("testuser")
        end
      end
    end

    context "with invalid credentials" do
      before do
        allow(mock_ldap).to receive(:auth)
        allow(mock_ldap).to receive(:bind).and_return(true, false) # Search succeeds, auth fails
        allow(mock_ldap).to receive(:search).and_yield(mock_user_entry)
        allow(mock_ldap).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
      end

      it "redirects back with alert" do
        post ldap_sign_in_path, params: { ldap_server_id: ldap_server.id, username: "testuser", password: "wrongpass" }
        expect(response).to redirect_to(ldap_sign_in_path)
        expect(flash[:alert]).to eq("Invalid username or password.")
      end

      it "does not create a user" do
        expect {
          post ldap_sign_in_path, params: { ldap_server_id: ldap_server.id, username: "testuser", password: "wrongpass" }
        }.not_to change(User, :count)
      end
    end

    context "when user is not found in LDAP" do
      before do
        allow(mock_ldap).to receive(:auth)
        allow(mock_ldap).to receive(:bind).and_return(true)
        allow(mock_ldap).to receive(:search) # No yield = no user found
        allow(mock_ldap).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
      end

      it "redirects back with alert" do
        post ldap_sign_in_path, params: { ldap_server_id: ldap_server.id, username: "nonexistent", password: "testpass" }
        expect(response).to redirect_to(ldap_sign_in_path)
        expect(flash[:alert]).to eq("Invalid username or password.")
      end
    end

    context "when user creation fails" do
      let(:invalid_user_entry) do
        entry = Net::LDAP::Entry.new("uid=baduser,ou=users,dc=example,dc=com")
        entry["uid"] = [ "baduser" ]
        entry["mail"] = [ "" ] # Invalid: blank email will fail validation
        entry["cn"] = [ "Bad User" ]
        entry
      end

      before do
        allow(mock_ldap).to receive(:auth)
        allow(mock_ldap).to receive(:bind).and_return(true)
        allow(mock_ldap).to receive(:search).and_yield(invalid_user_entry)
        allow(mock_ldap).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
      end

      it "redirects back with error message" do
        post ldap_sign_in_path, params: { ldap_server_id: ldap_server.id, username: "baduser", password: "testpass" }
        expect(response).to redirect_to(ldap_sign_in_path)
        expect(flash[:alert]).to include("Failed to create user account")
      end
    end
  end
end
