# frozen_string_literal: true

class BuyerProfile < ApplicationRecord
  include SoftDeletable
  include Auditable

  # Finance status options
  FINANCE_STATUSES = %w[cash pre_approved needs_finance exploring].freeze

  # Buying timeline options
  BUYING_TIMELINES = %w[immediate 3_months 6_months just_looking].freeze

  # Property types
  PROPERTY_TYPES = %w[house townhouse apartment land rural].freeze

  # Must-have features
  FEATURES = %w[
    garage garden pool air_conditioning solar study granny_flat
    ensuite walk_in_robe dishwasher built_in_wardrobes balcony
    courtyard water_views city_views north_facing
  ].freeze

  belongs_to :user
  belongs_to :default_entity, class_name: "Entity", optional: true

  validates :finance_status, inclusion: { in: FINANCE_STATUSES }, allow_blank: true
  validates :buying_timeline, inclusion: { in: BUYING_TIMELINES }, allow_blank: true
  validates :budget_min_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :budget_max_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :budget_max_greater_than_min

  # Scopes
  scope :pre_approved, -> { where(finance_status: "pre_approved") }
  scope :cash_buyers, -> { where(finance_status: "cash") }
  scope :first_home_buyers, -> { where(first_home_buyer: true) }
  scope :active_buyers, -> { where(buying_timeline: %w[immediate 3_months]) }

  # Budget helpers
  def budget_min
    return nil unless budget_min_cents

    budget_min_cents / 100.0
  end

  def budget_min=(value)
    self.budget_min_cents = value.present? ? (value.to_f * 100).to_i : nil
  end

  def budget_max
    return nil unless budget_max_cents

    budget_max_cents / 100.0
  end

  def budget_max=(value)
    self.budget_max_cents = value.present? ? (value.to_f * 100).to_i : nil
  end

  def budget_range
    return nil unless budget_min_cents && budget_max_cents

    budget_min..budget_max
  end

  # Pre-approval helpers
  def pre_approval_amount
    return nil unless pre_approval_amount_cents

    pre_approval_amount_cents / 100.0
  end

  def pre_approval_amount=(value)
    self.pre_approval_amount_cents = value.present? ? (value.to_f * 100).to_i : nil
  end

  def pre_approval_valid?
    return false unless finance_status == "pre_approved"
    return false unless pre_approval_expires_at.present?

    pre_approval_expires_at > Date.current
  end

  def pre_approval_expiring_soon?
    return false unless pre_approval_valid?

    pre_approval_expires_at <= 2.weeks.from_now
  end

  # Finance helpers
  def cash_buyer?
    finance_status == "cash"
  end

  def pre_approved?
    finance_status == "pre_approved"
  end

  def needs_finance?
    finance_status == "needs_finance"
  end

  def exploring?
    finance_status == "exploring"
  end

  # Location preference helpers
  def near_primary_school?
    location_preferences.dig("near_primary_school", "enabled")
  end

  def near_secondary_school?
    location_preferences.dig("near_secondary_school", "enabled")
  end

  def near_train_station?
    location_preferences.dig("near_train_station", "enabled")
  end

  def near_bus_stop?
    location_preferences.dig("near_bus_stop", "enabled")
  end

  # Property love/unlove helpers
  def love_property(property)
    PropertyLove.find_or_create_by(user: user, property: property)
  end

  def unlove_property(property)
    PropertyLove.find_by(user: user, property: property)&.destroy
  end

  def loves_property?(property)
    PropertyLove.exists?(user: user, property: property)
  end

  private

  def budget_max_greater_than_min
    return unless budget_min_cents && budget_max_cents
    return if budget_max_cents >= budget_min_cents

    errors.add(:budget_max_cents, "must be greater than or equal to minimum budget")
  end
end
