# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Set Current attributes for audit logging
  before_action :set_current_attributes
  before_action :set_locale

  # Pundit authorization - use method checks instead of only:/except: to avoid
  # Rails 7.1 callback errors when actions don't exist in a controller
  after_action :verify_authorized, unless: :skip_authorization_verification?
  after_action :verify_policy_scoped, if: :verify_policy_scoped?

  # Handle Pundit authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Pagination
  include Pagy::Backend

  protected

  # Configure Devise permitted parameters
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :name, :phone, :phone_country_code, :preferred_language, :timezone,
      roles: []
    ])
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :name, :phone, :phone_country_code, :preferred_language, :timezone,
      notification_preferences: {}
    ])
  end

  # Devise: redirect after sign in based on role
  def after_sign_in_path_for(resource)
    if resource.needs_to_accept_legal_documents?
      accept_terms_path
    elsif resource.onboarding_completed_at.nil?
      onboarding_path
    else
      dashboard_path
    end
  end

  private

  def set_current_attributes
    Current.user = current_user
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
    Current.session_id = session.id.to_s
    Current.request_id = request.request_id

    # Check for admin impersonation
    if session[:admin_user_id] && current_user
      Current.admin_user = User.find_by(id: session[:admin_user_id])
    end
  end

  def set_locale
    I18n.locale = if current_user&.preferred_language.present?
      current_user.preferred_language
    else
      extract_locale_from_header || I18n.default_locale
    end
  end

  def extract_locale_from_header
    accept_language = request.env["HTTP_ACCEPT_LANGUAGE"]
    return nil unless accept_language

    accepted = accept_language.scan(/[a-z]{2}/).first
    I18n.available_locales.include?(accepted&.to_sym) ? accepted : nil
  end

  def skip_pundit?
    devise_controller? || params[:controller].start_with?("active_storage")
  end

  # Skip verify_authorized for index actions and when skip_pundit? is true
  def skip_authorization_verification?
    skip_pundit? || action_name == "index"
  end

  # Only run verify_policy_scoped on index actions when not skipping pundit
  def verify_policy_scoped?
    !skip_pundit? && action_name == "index"
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end

  # Helper to check subscription status
  def require_active_subscription!
    return if current_user&.active_subscription?

    redirect_to subscription_path, alert: "Please subscribe to access this feature."
  end

  # Helper to check KYC verification
  def require_kyc_verification!
    return if current_user&.kyc_verified?

    redirect_to kyc_verification_path, alert: "Please complete identity verification to continue."
  end

  # Helper to check role
  def require_role!(*roles)
    return if roles.any? { |role| current_user&.send("#{role}?") }

    redirect_to dashboard_path, alert: "You don't have permission to access this area."
  end

  # Helper for admin-only areas
  def require_admin!
    require_role!(:admin)
  end
end
