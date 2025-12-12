# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  protected

  def after_sign_up_path_for(resource)
    onboarding_path
  end

  def after_update_path_for(resource)
    dashboard_path
  end
end
