# frozen_string_literal: true

# Thread-safe storage for request-specific attributes.
# Used by Auditable concern and other parts of the system
# to access the current user, IP address, and other request context.
#
# Set these attributes in ApplicationController:
#   Current.user = current_user
#   Current.ip_address = request.remote_ip
#   Current.user_agent = request.user_agent
#   Current.session_id = session.id
#   Current.request_id = request.request_id
#
class Current < ActiveSupport::CurrentAttributes
  # The currently authenticated user
  attribute :user

  # Admin user if impersonating another user
  attribute :admin_user

  # Request context for audit logging
  attribute :ip_address
  attribute :user_agent
  attribute :session_id
  attribute :request_id

  # Check if current session is an impersonation
  def impersonating?
    admin_user.present? && user.present? && admin_user != user
  end
end
