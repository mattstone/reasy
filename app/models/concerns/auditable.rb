# frozen_string_literal: true

# Provides audit logging functionality for models.
# Automatically logs create, update, and delete actions to the AuditLog table.
#
# Usage:
#   class Property < ApplicationRecord
#     include Auditable
#   end
#
# All changes will be automatically logged with:
# - User who made the change (from Current.user)
# - Admin user if impersonating (from Current.admin_user)
# - IP address, user agent, session and request IDs
# - Before/after values for all changed attributes
#
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create { log_audit("created") }
    after_update { log_audit("updated") }
    after_destroy { log_audit("deleted") }
  end

  private

  def log_audit(action)
    return unless should_audit?

    changes_to_log = action == "updated" ? saved_changes.except("updated_at") : {}

    AuditLog.create!(
      user_id: Current.user&.id,
      impersonated_by_id: Current.admin_user&.id,
      action_type: "#{self.class.name.underscore}.#{action}",
      resource_type: self.class.name,
      resource_id: id,
      recorded_changes: changes_to_log,
      metadata: audit_metadata,
      ip_address: Current.ip_address,
      user_agent: Current.user_agent,
      session_id: Current.session_id,
      request_id: Current.request_id
    )
  rescue StandardError => e
    # Log but don't fail the original operation
    Rails.logger.error("Failed to create audit log: #{e.message}")
  end

  def should_audit?
    # Skip auditing in test environment unless explicitly enabled
    return false if Rails.env.test? && !Thread.current[:enable_audit_logging]

    true
  end

  # Override in model to add additional metadata
  def audit_metadata
    {}
  end
end
