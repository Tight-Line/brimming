# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Skipped in test environment as RSpec uses a simple HTTP client without browser headers.
  unless Rails.env.test?
    allow_browser versions: :modern
  end

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :store_return_to, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :username, :full_name, :avatar_url ])
  end

  # Store return_to URL for post-sign-in redirect
  def store_return_to
    return_to = params[:return_to]
    if return_to.present? && return_to.start_with?("/")
      store_location_for(:user, return_to)
    end
  end

  # Override Devise's after_sign_in_path
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end

  # Override Devise's after_sign_up_path
  def after_sign_up_path_for(resource)
    stored_location_for(resource) || root_path
  end

  def require_login
    return if user_signed_in?

    respond_to do |format|
      format.html { redirect_to new_user_session_path, alert: "You must be signed in to do that." }
      format.turbo_stream { head :unauthorized }
      format.json { render json: { error: "Unauthorized" }, status: :unauthorized }
    end
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end
end
