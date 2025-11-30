# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    layout "admin"
    before_action :require_admin

    private

    def require_admin
      unless current_user&.admin?
        redirect_to root_path, alert: "You must be an admin to access this area."
      end
    end
  end
end
