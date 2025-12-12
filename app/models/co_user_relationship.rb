# frozen_string_literal: true

class CoUserRelationship < ApplicationRecord
  include Auditable

  # Relationship statuses
  STATUSES = %w[active suspended revoked].freeze

  # Subscription statuses for co-users (80% discount)
  SUBSCRIPTION_STATUSES = %w[trial active past_due cancelled].freeze

  belongs_to :primary_user, class_name: "User"
  belongs_to :co_user, class_name: "User"
  belongs_to :co_user_invitation, optional: true

  validates :status, inclusion: { in: STATUSES }
  validates :subscription_status, inclusion: { in: SUBSCRIPTION_STATUSES }
  validates :co_user_id, uniqueness: { scope: :primary_user_id, message: "is already a co-user for this account" }

  validate :maximum_co_users_per_primary, on: :create
  validate :cannot_be_own_co_user

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :suspended, -> { where(status: "suspended") }
  scope :revoked, -> { where(status: "revoked") }
  scope :with_active_subscription, -> { where(subscription_status: %w[trial active]) }
  scope :recent, -> { order(created_at: :desc) }

  # Status helpers
  def active?
    status == "active"
  end

  def suspended?
    status == "suspended"
  end

  def revoked?
    status == "revoked"
  end

  # Permission helpers
  def can_view_listings?
    active? && can_view_listings
  end

  def can_view_offers?
    active? && can_view_offers
  end

  def can_send_messages?
    active? && can_send_messages
  end

  def can_schedule_viewings?
    active? && can_schedule_viewings
  end

  def can_make_offers?
    active? && can_make_offers
  end

  # Check if co-user can perform an action
  def permitted_to?(action)
    case action.to_sym
    when :view_listings then can_view_listings?
    when :view_offers then can_view_offers?
    when :send_messages then can_send_messages?
    when :schedule_viewings then can_schedule_viewings?
    when :make_offers then can_make_offers?
    else false
    end
  end

  # Update permissions
  def update_permissions!(permissions_hash)
    update!(
      can_view_listings: permissions_hash[:can_view_listings] || can_view_listings,
      can_view_offers: permissions_hash[:can_view_offers] || can_view_offers,
      can_send_messages: permissions_hash[:can_send_messages] || can_send_messages,
      can_schedule_viewings: permissions_hash[:can_schedule_viewings] || can_schedule_viewings,
      can_make_offers: permissions_hash[:can_make_offers] || can_make_offers
    )
  end

  # Status transitions
  def suspend!(reason: nil)
    return false unless active?

    update!(status: "suspended")
  end

  def reactivate!
    return false unless suspended?

    update!(status: "active")
  end

  def revoke!
    return false if revoked?

    update!(status: "revoked")
  end

  # Subscription helpers
  def subscription_active?
    subscription_status.in?(%w[trial active])
  end

  def trial?
    subscription_status == "trial"
  end

  # Relationship display
  def relationship_display
    relationship&.titleize || "Co-user"
  end

  private

  def maximum_co_users_per_primary
    return unless primary_user
    return if primary_user.can_add_co_users?

    errors.add(:primary_user, "has reached the maximum number of co-users (2)")
  end

  def cannot_be_own_co_user
    return unless primary_user_id == co_user_id

    errors.add(:co_user, "cannot be the same as primary user")
  end
end
