# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Skip in test environment as RSpec uses a simple HTTP client without browser headers
  unless Rails.env.test?
    allow_browser versions: :modern
  end

  helper_method :current_user, :signed_in?

  # Stub authentication - returns the first user in the database
  # TODO: Replace with proper authentication (Devise) in Phase 4
  def current_user
    @current_user ||= User.first
  end

  def signed_in?
    current_user.present?
  end

  private

  def require_login
    return if signed_in?

    respond_to do |format|
      format.html { redirect_to root_path, alert: "You must be signed in to do that." }
      format.turbo_stream { head :unauthorized }
      format.json { render json: { error: "Unauthorized" }, status: :unauthorized }
    end
  end
end
