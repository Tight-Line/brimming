# frozen_string_literal: true

require "rails_helper"

RSpec.describe LdapAuthenticationService, type: :service do
  let(:ldap_server) { create(:ldap_server) }
  let(:username) { "testuser" }
  let(:password) { "testpass" }
  let(:service) { described_class.new(ldap_server, username, password) }

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

  describe "#authenticate" do
    context "when server is disabled" do
      let(:ldap_server) { create(:ldap_server, :disabled) }

      it "returns nil" do
        expect(service.authenticate).to be_nil
      end

      it "does not attempt LDAP connection" do
        service.authenticate
        expect(Net::LDAP).not_to have_received(:new)
      end
    end

    context "when user is found and password is valid" do
      before do
        allow(mock_ldap).to receive(:auth)
        allow(mock_ldap).to receive(:bind).and_return(true)
        allow(mock_ldap).to receive(:search).and_yield(mock_user_entry)
        allow(mock_ldap).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
      end

      it "returns the user entry" do
        expect(service.authenticate).to eq(mock_user_entry)
      end
    end

    context "when user is not found" do
      before do
        allow(mock_ldap).to receive(:auth)
        allow(mock_ldap).to receive(:bind).and_return(true)
        allow(mock_ldap).to receive(:search) # No yield = no results
        allow(mock_ldap).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
      end

      it "returns nil" do
        expect(service.authenticate).to be_nil
      end
    end

    context "when password is invalid" do
      before do
        allow(mock_ldap).to receive(:auth)
        allow(mock_ldap).to receive(:bind).and_return(true, false) # First bind succeeds (search), second fails (verify)
        allow(mock_ldap).to receive(:search).and_yield(mock_user_entry)
        allow(mock_ldap).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
      end

      it "returns nil" do
        expect(service.authenticate).to be_nil
      end
    end

    context "when password is blank" do
      let(:password) { "" }

      before do
        allow(mock_ldap).to receive(:auth)
        allow(mock_ldap).to receive(:bind).and_return(true)
        allow(mock_ldap).to receive(:search).and_yield(mock_user_entry)
        allow(mock_ldap).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
      end

      it "returns nil" do
        expect(service.authenticate).to be_nil
      end
    end

    context "when LDAP search fails with error" do
      before do
        allow(mock_ldap).to receive(:auth)
        allow(mock_ldap).to receive(:bind).and_return(true)
        allow(mock_ldap).to receive(:search).and_raise(Net::LDAP::Error.new("Connection failed"))
        allow(mock_ldap).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
      end

      it "returns nil" do
        expect(service.authenticate).to be_nil
      end
    end

    context "when server has no bind credentials" do
      let(:ldap_server) { create(:ldap_server, bind_dn: nil, bind_password: nil) }

      before do
        allow(mock_ldap).to receive(:auth)
        allow(mock_ldap).to receive(:bind).and_return(true)
        allow(mock_ldap).to receive(:search).and_yield(mock_user_entry)
        allow(mock_ldap).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
      end

      it "logs a warning about missing bind credentials" do
        expect(Rails.logger).to receive(:warn).with(/No bind credentials configured/)
        service.authenticate
      end

      it "still attempts to authenticate" do
        expect(service.authenticate).to eq(mock_user_entry)
      end
    end

    context "when LDAP bind fails with error during password verification" do
      before do
        # First call for user search
        allow(mock_ldap).to receive(:auth)
        allow(mock_ldap).to receive(:search).and_yield(mock_user_entry)
        allow(mock_ldap).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
        # First bind succeeds (for search), then raises error (for password verification)
        call_count = 0
        allow(mock_ldap).to receive(:bind) do
          call_count += 1
          if call_count == 1
            true
          else
            raise Net::LDAP::Error.new("Connection reset")
          end
        end
      end

      it "returns nil and logs the error" do
        expect(Rails.logger).to receive(:error).with(/LDAP bind failed/)
        expect(service.authenticate).to be_nil
      end
    end
  end

  describe "#fetch_groups" do
    let(:user_dn) { "uid=testuser,ou=users,dc=example,dc=com" }
    let(:group_entry) do
      entry = Net::LDAP::Entry.new("cn=developers,ou=groups,dc=example,dc=com")
      entry
    end

    context "when group search base is blank" do
      let(:ldap_server) { create(:ldap_server, group_search_base: nil) }

      it "returns empty array" do
        expect(service.fetch_groups(user_dn)).to eq([])
      end
    end

    context "when groups are found" do
      before do
        allow(mock_ldap).to receive(:auth)
        allow(mock_ldap).to receive(:bind).and_return(true)
        allow(mock_ldap).to receive(:search).and_yield(group_entry)
        allow(mock_ldap).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
      end

      it "returns group DNs" do
        groups = service.fetch_groups(user_dn)
        expect(groups).to eq([ "cn=developers,ou=groups,dc=example,dc=com" ])
      end
    end

    context "when LDAP error occurs" do
      before do
        allow(mock_ldap).to receive(:auth)
        allow(mock_ldap).to receive(:bind).and_return(true)
        allow(mock_ldap).to receive(:search).and_raise(Net::LDAP::Error.new("Connection failed"))
        allow(mock_ldap).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
      end

      it "returns empty array" do
        expect(service.fetch_groups(user_dn)).to eq([])
      end
    end
  end

  describe "#build_auth_hash" do
    let(:groups) { [ "cn=developers,ou=groups,dc=example,dc=com" ] }

    it "builds an OmniAuth-compatible hash" do
      hash = service.build_auth_hash(mock_user_entry, groups)

      expect(hash[:provider]).to eq("ldap")
      expect(hash[:uid]).to eq("testuser")
      expect(hash[:info][:email]).to eq("testuser@example.com")
      expect(hash[:info][:name]).to eq("Test User")
      expect(hash[:info][:nickname]).to eq("testuser")
      expect(hash[:extra][:raw_info][:dn]).to eq("uid=testuser,ou=users,dc=example,dc=com")
      expect(hash[:extra][:raw_info][:groups]).to eq(groups)
    end

    context "when user entry has missing attributes" do
      let(:sparse_user_entry) do
        entry = Net::LDAP::Entry.new("uid=sparse,ou=users,dc=example,dc=com")
        # Only set uid, leave mail and cn missing
        entry["uid"] = [ "sparse" ]
        entry
      end

      it "handles nil values for missing attributes" do
        hash = service.build_auth_hash(sparse_user_entry, [])

        expect(hash[:provider]).to eq("ldap")
        expect(hash[:uid]).to eq("sparse")
        expect(hash[:info][:email]).to be_nil
        expect(hash[:info][:name]).to be_nil
        expect(hash[:info][:nickname]).to eq("sparse")
      end
    end

    context "when ldap server uses non-standard attribute names" do
      let(:ldap_server_custom_attrs) do
        create(:ldap_server,
               uid_attribute: "sAMAccountName",
               email_attribute: "userPrincipalName",
               name_attribute: "displayName")
      end
      let(:custom_service) { described_class.new(ldap_server_custom_attrs, username, password) }

      it "uses configured attribute names and handles nil gracefully" do
        # Entry doesn't have the custom attributes, should return nil via &.first
        hash = custom_service.build_auth_hash(mock_user_entry, [])

        # Since mock_user_entry has uid/mail/cn but NOT sAMAccountName/userPrincipalName/displayName
        expect(hash[:uid]).to be_nil
        expect(hash[:info][:email]).to be_nil
        expect(hash[:info][:name]).to be_nil
        expect(hash[:info][:nickname]).to be_nil
      end
    end
  end

  describe "private escape_ldap method" do
    it "escapes special LDAP characters" do
      # Test the escaping logic directly
      # Characters that should be escaped: , \ # + < > ; " =
      test_cases = {
        "normal" => "normal",
        "test,user" => "test\\,user",
        "user\\name" => "user\\\\name",
        "test#user" => "test\\#user",
        "test+user" => "test\\+user",
        "test<user" => "test\\<user",
        "test>user" => "test\\>user",
        'test"user' => 'test\\"user',
        "test=user" => "test\\=user",
        "test;user" => "test\\;user"
      }

      test_cases.each do |input, expected|
        result = service.send(:escape_ldap, input)
        expect(result).to eq(expected), "Expected escape_ldap(#{input.inspect}) to equal #{expected.inspect}, got #{result.inspect}"
      end
    end
  end
end
