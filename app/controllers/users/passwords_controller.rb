# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  protected

  def after_resetting_password_path_for(resource)
    dashboard_path
  end
end
