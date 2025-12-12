# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  protected

  def after_sign_in_path_for(resource)
    if resource.onboarding_completed_at.nil?
      onboarding_path
    else
      dashboard_path
    end
  end

  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end
end
