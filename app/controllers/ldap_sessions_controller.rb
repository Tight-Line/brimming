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

      # Find or create user
      user = find_or_create_user_from_ldap(auth_hash)

      if user.persisted?
        # Store LDAP server ID for later use (e.g., settings page)
        session[:ldap_server_id] = @ldap_server.id

        # Process space registrations
        LdapSpaceRegistrationService.new(user, @ldap_server, groups).process!

        sign_in(user)
        redirect_to root_path, notice: "Signed in successfully via #{@ldap_server.name}."
      else
        redirect_to ldap_sign_in_path, alert: "Failed to create user account: #{user.errors.full_messages.join(', ')}"
      end
    else
      redirect_to ldap_sign_in_path, alert: "Invalid username or password."
    end
  end

  private

  def set_ldap_server
    @ldap_server = LdapServer.enabled.find_by(id: params[:ldap_server_id])
  end

  def find_or_create_user_from_ldap(auth_hash)
    email = auth_hash[:info][:email]
    uid = auth_hash[:uid]

    user = User.find_by(provider: "ldap", uid: uid)
    user ||= User.find_by(email: email)

    if user
      user.update!(
        provider: "ldap",
        uid: uid,
        ldap_dn: auth_hash[:extra][:raw_info][:dn],
        full_name: auth_hash[:info][:name].presence || user.full_name
      )
    else
      user = User.new(
        provider: "ldap",
        uid: uid,
        ldap_dn: auth_hash[:extra][:raw_info][:dn],
        email: email,
        username: User.generate_unique_username(auth_hash[:info][:nickname] || email.split("@").first),
        full_name: auth_hash[:info][:name],
        password: Devise.friendly_token[0, 20]
      )
      user.save
    end

    user
  end
end
