# frozen_string_literal: true

class EmailVerificationsController < ApplicationController
  # This controller is intentionally public - no authentication required
  # Anyone with a valid verification token should be able to verify their email

  def show
    @user_email = UserEmail.find_by(verification_token: params[:token])

    if @user_email.nil?
      redirect_to root_path, alert: "Invalid or expired verification link."
    elsif @user_email.verified?
      redirect_to root_path, notice: "This email has already been verified."
    else
      @user_email.verify!
      redirect_to root_path, notice: "Your email address has been verified."
    end
  end
end
