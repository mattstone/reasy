# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  protected

  def after_confirmation_path_for(_resource_name, resource)
    sign_in(resource)
    onboarding_path
  end
end
