# frozen_string_literal: true

class UserEmailMailer < ApplicationMailer
  def verification_email(user_email)
    @user_email = user_email
    @user = user_email.user
    @verification_url = verify_email_url(token: user_email.verification_token)

    mail(
      to: user_email.email,
      subject: "Verify your email address"
    )
  end
end
