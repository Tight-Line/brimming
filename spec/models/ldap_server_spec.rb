# frozen_string_literal: true

require "rails_helper"

RSpec.describe LdapServer, type: :model do
  describe "validations" do
    subject { build(:ldap_server) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:host) }
    it { should validate_presence_of(:port) }
    it { should validate_numericality_of(:port).only_integer.is_greater_than(0).is_less_than(65_536) }
    it { should validate_presence_of(:encryption) }
    it { should validate_inclusion_of(:encryption).in_array(LdapServer::ENCRYPTION_OPTIONS) }
    it { should validate_presence_of(:user_search_base) }
    it { should validate_presence_of(:uid_attribute) }
    it { should validate_presence_of(:email_attribute) }
  end

  describe "associations" do
    it { should have_many(:ldap_group_mappings).dependent(:destroy) }
  end

  describe "scopes" do
    describe ".enabled" do
      let!(:enabled_server) { create(:ldap_server, enabled: true) }
      let!(:disabled_server) { create(:ldap_server, :disabled) }

      it "returns only enabled servers" do
        expect(LdapServer.enabled).to contain_exactly(enabled_server)
      end
    end
  end

  describe "#encryption_method" do
    it "returns nil for plain encryption" do
      server = build(:ldap_server, encryption: "plain")
      expect(server.encryption_method).to be_nil
    end

    it "returns :start_tls for start_tls encryption" do
      server = build(:ldap_server, encryption: "start_tls")
      expect(server.encryption_method).to eq(:start_tls)
    end

    it "returns :simple_tls for simple_tls encryption" do
      server = build(:ldap_server, encryption: "simple_tls")
      expect(server.encryption_method).to eq(:simple_tls)
    end
  end

  describe "#connection_options" do
    let(:server) { build(:ldap_server) }

    it "includes host, port, and base" do
      options = server.connection_options
      expect(options[:host]).to eq(server.host)
      expect(options[:port]).to eq(server.port)
      expect(options[:base]).to eq(server.user_search_base)
    end

    it "includes auth when bind credentials are present" do
      options = server.connection_options
      expect(options[:auth]).to eq({
        method: :simple,
        username: server.bind_dn,
        password: server.bind_password
      })
    end

    it "does not include auth when bind_dn is blank" do
      server.bind_dn = nil
      options = server.connection_options
      expect(options[:auth]).to be_nil
    end

    it "does not include auth when bind_password is blank" do
      server.bind_password = nil
      options = server.connection_options
      expect(options[:auth]).to be_nil
    end

    it "includes encryption when not plain" do
      server.encryption = "start_tls"
      options = server.connection_options
      expect(options[:encryption]).to eq({ method: :start_tls })
    end

    it "does not include encryption for plain" do
      server.encryption = "plain"
      options = server.connection_options
      expect(options[:encryption]).to be_nil
    end
  end

  describe "#omniauth_config" do
    let(:server) { build(:ldap_server) }

    it "returns a hash with LDAP configuration" do
      config = server.omniauth_config
      expect(config[:host]).to eq(server.host)
      expect(config[:port]).to eq(server.port)
      expect(config[:method]).to eq(:plain)
      expect(config[:base]).to eq(server.user_search_base)
      expect(config[:uid]).to eq(server.uid_attribute)
      expect(config[:bind_dn]).to eq(server.bind_dn)
      expect(config[:password]).to eq(server.bind_password)
      expect(config[:filter]).to eq(server.user_search_filter)
    end

    it "omits nil values" do
      server.bind_dn = nil
      config = server.omniauth_config
      expect(config).not_to have_key(:bind_dn)
    end

    it "includes a name_proc that returns the name unchanged" do
      config = server.omniauth_config
      expect(config[:name_proc]).to be_a(Proc)
      expect(config[:name_proc].call("Test User")).to eq("Test User")
    end
  end
end
