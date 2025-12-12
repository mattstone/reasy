# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    layout "admin"

    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    private

    def require_admin!
      unless current_user&.admin?
        flash[:error] = "You don't have permission to access this area."
        redirect_to root_path
      end
    end
  end
end
