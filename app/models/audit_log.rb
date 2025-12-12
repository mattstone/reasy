# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :impersonated_by, class_name: "User", optional: true

  validates :action_type, presence: true
  validates :resource_type, presence: true
  validates :resource_id, presence: true

  # Alias for the recorded_changes column (renamed from 'changes' to avoid AR conflict)
  alias_attribute :changes_made, :recorded_changes

  scope :for_user, ->(user) { where(user: user) }
  scope :for_resource, ->(type, id) { where(resource_type: type, resource_id: id) }
  scope :by_action, ->(action) { where(action_type: action) }
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where(created_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :this_week, -> { where(created_at: 1.week.ago..Time.current) }
  scope :impersonated, -> { where.not(impersonated_by_id: nil) }

  # Action type patterns
  PATTERNS = {
    created: /\.created$/,
    updated: /\.updated$/,
    deleted: /\.deleted$/,
    ai: /^ai\./,
    property: /^property\./,
    offer: /^offer\./,
    review: /^review\./
  }.freeze

  def self.action_types
    distinct.pluck(:action_type).sort
  end

  def self.resource_types
    distinct.pluck(:resource_type).sort
  end

  def created_action?
    action_type.match?(PATTERNS[:created])
  end

  def updated_action?
    action_type.match?(PATTERNS[:updated])
  end

  def deleted_action?
    action_type.match?(PATTERNS[:deleted])
  end

  def ai_action?
    action_type.match?(PATTERNS[:ai])
  end

  def impersonated?
    impersonated_by_id.present?
  end

  def resource
    @resource ||= resource_type.constantize.unscoped.find_by(id: resource_id)
  rescue NameError
    nil
  end
end
