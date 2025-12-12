# frozen_string_literal: true

# Provides soft delete functionality for models.
# Instead of permanently deleting records, sets a deleted_at timestamp.
# Records can be restored by setting deleted_at back to nil.
#
# Usage:
#   class User < ApplicationRecord
#     include SoftDeletable
#   end
#
#   user.soft_delete   # Sets deleted_at to current time
#   user.restore       # Sets deleted_at to nil
#   user.deleted?      # Returns true if deleted_at is present
#
#   User.kept          # Returns records that haven't been soft deleted
#   User.deleted       # Returns records that have been soft deleted
#   User.with_deleted  # Returns all records including soft deleted
#
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    # Default scope excludes soft-deleted records
    default_scope { kept }

    scope :kept, -> { where(deleted_at: nil) }
    scope :deleted, -> { unscoped.where.not(deleted_at: nil) }
    scope :with_deleted, -> { unscoped }
  end

  # Soft delete the record by setting deleted_at timestamp
  def soft_delete
    update_column(:deleted_at, Time.current)
  end

  # Restore a soft-deleted record
  def restore
    update_column(:deleted_at, nil)
  end

  # Check if the record has been soft deleted
  def deleted?
    deleted_at.present?
  end

  # Check if the record is active (not deleted)
  def kept?
    deleted_at.nil?
  end

  # Override destroy to perform soft delete instead
  def destroy
    run_callbacks(:destroy) do
      soft_delete
    end
  end

  # Allow hard delete when explicitly needed
  def destroy!
    self.class.unscoped { super }
  end

  # Allow hard delete with skip_callbacks
  def really_destroy!
    self.class.unscoped { delete }
  end
end
