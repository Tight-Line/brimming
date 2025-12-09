# frozen_string_literal: true

module Settings
  class ProfilesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user_email, only: [ :remove_email, :set_primary_email, :resend_verification ]

    def edit
      @user = current_user
      @user_emails = current_user.user_emails.order(primary: :desc, created_at: :asc)
    end

    def update
      @user = current_user

      if @user.update(profile_params)
        redirect_to edit_settings_profile_path, notice: "Profile updated successfully."
      else
        @user_emails = current_user.user_emails.order(primary: :desc, created_at: :asc)
        render :edit, status: :unprocessable_entity
      end
    end

    def add_email
      email_address = params[:email]&.downcase&.strip

      if email_address.blank?
        redirect_to edit_settings_profile_path, alert: "Please enter an email address."
        return
      end

      if current_user.has_email?(email_address)
        redirect_to edit_settings_profile_path, alert: "You already have this email address."
        return
      end

      user_email = current_user.add_email(email_address)

      if user_email.persisted?
        user_email.send_verification!
        redirect_to edit_settings_profile_path, notice: "Verification email sent to #{email_address}."
      else
        redirect_to edit_settings_profile_path, alert: user_email.errors.full_messages.join(", ")
      end
    end

    def remove_email
      if @user_email.primary?
        redirect_to edit_settings_profile_path, alert: "Cannot remove your primary email address."
        return
      end

      @user_email.destroy
      redirect_to edit_settings_profile_path, notice: "Email address removed."
    end

    def set_primary_email
      unless @user_email.verified?
        redirect_to edit_settings_profile_path, alert: "Only verified emails can be set as primary."
        return
      end

      @user_email.mark_as_primary!
      redirect_to edit_settings_profile_path, notice: "Primary email updated to #{@user_email.email}."
    end

    def resend_verification
      if @user_email.verified?
        redirect_to edit_settings_profile_path, alert: "This email is already verified."
        return
      end

      @user_email.send_verification!
      redirect_to edit_settings_profile_path, notice: "Verification email sent to #{@user_email.email}."
    end

    private

    def set_user_email
      @user_email = current_user.user_emails.find_by(id: params[:email_id])

      unless @user_email
        redirect_to edit_settings_profile_path, alert: "Email not found."
      end
    end

    def profile_params
      params.require(:user).permit(:full_name, :timezone, :avatar)
    end
  end
end
