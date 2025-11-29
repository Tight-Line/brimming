# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Skip in test environment as RSpec uses a simple HTTP client without browser headers
  unless Rails.env.test?
    allow_browser versions: :modern
  end

  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :username, :full_name, :avatar_url ])
  end

  def require_login
    return if user_signed_in?

    respond_to do |format|
      format.html { redirect_to new_user_session_path, alert: "You must be signed in to do that." }
      format.turbo_stream { head :unauthorized }
      format.json { render json: { error: "Unauthorized" }, status: :unauthorized }
    end
  end
end
