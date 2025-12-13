# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout :resolve_layout
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  protected

  def after_sign_up_path_for(resource)
    onboarding_path
  end

  def after_update_path_for(resource)
    dashboard_path
  end

  private

  def resolve_layout
    if action_name == "edit" || action_name == "update"
      "dashboard"
    else
      "application"
    end
  end
end
