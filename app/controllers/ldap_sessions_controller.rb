# frozen_string_literal: true

class LdapSessionsController < ApplicationController
  before_action :set_ldap_server, only: [ :create ]

  # GET /ldap/sign_in
  def new
    @ldap_servers = LdapServer.enabled.order(:name)

    if @ldap_servers.empty?
      redirect_to new_user_session_path, alert: "No LDAP servers are configured."
    end
  end

  # POST /ldap/sign_in
  def create
    unless @ldap_server
      redirect_to ldap_sign_in_path, alert: "Please select an LDAP server."
      return
    end

    username = params[:username]
    password = params[:password]

    if username.blank? || password.blank?
      redirect_to ldap_sign_in_path, alert: "Username and password are required."
      return
    end

    # Authenticate against LDAP
    auth_service = LdapAuthenticationService.new(@ldap_server, username, password)
    user_entry = auth_service.authenticate

    if user_entry
      # Fetch groups and build auth hash
      groups = auth_service.fetch_groups(user_entry.dn)
      auth_hash = auth_service.build_auth_hash(user_entry, groups)

      # Find or create user using the centralized method
      begin
        user = User.from_omniauth(build_omniauth_hash(auth_hash), @ldap_server)

        # Store LDAP server ID for later use (e.g., settings page)
        session[:ldap_server_id] = @ldap_server.id

        # Process space registrations
        LdapSpaceRegistrationService.new(user, @ldap_server, groups).process!

        sign_in(user)
        redirect_to root_path, notice: "Signed in successfully via #{@ldap_server.name}."
      rescue User::UnverifiedEmailError => e
        redirect_to ldap_sign_in_path,
          alert: "The email address #{e.email} is already registered but not verified. " \
                 "Please verify your email first or use the password reset option."
      rescue ActiveRecord::RecordInvalid => e
        redirect_to ldap_sign_in_path, alert: "Failed to create user account: #{e.record.errors.full_messages.join(', ')}"
      end
    else
      redirect_to ldap_sign_in_path, alert: "Invalid username or password."
    end
  end

  private

  def set_ldap_server
    @ldap_server = LdapServer.enabled.find_by(id: params[:ldap_server_id])
  end

  # Convert our auth_hash to an OpenStruct that mimics OmniAuth's structure
  def build_omniauth_hash(auth_hash)
    OpenStruct.new(
      provider: auth_hash[:provider],
      uid: auth_hash[:uid],
      info: OpenStruct.new(
        email: auth_hash[:info][:email],
        name: auth_hash[:info][:name],
        nickname: auth_hash[:info][:nickname]
      ),
      extra: OpenStruct.new(
        raw_info: OpenStruct.new(
          dn: auth_hash[:extra][:raw_info][:dn]
        )
      )
    )
  end
end
