# frozen_string_literal: true

class SellerProfile < ApplicationRecord
  include SoftDeletable
  include Auditable

  # Settlement period options
  SETTLEMENT_PERIODS = %w[asap standard flexible specific].freeze

  # Contact methods
  CONTACT_METHODS = %w[platform email phone].freeze

  belongs_to :user
  belongs_to :default_entity, class_name: "Entity", optional: true

  validates :preferred_settlement_period, inclusion: { in: SETTLEMENT_PERIODS }
  validates :preferred_contact_method, inclusion: { in: CONTACT_METHODS }
  validates :specific_settlement_date, presence: true, if: -> { preferred_settlement_period == "specific" }

  # Scopes
  scope :accepting_cash, -> { where(accept_cash_buyers: true) }
  scope :accepting_pre_approved, -> { where(accept_pre_approved_buyers: true) }
  scope :accepting_finance, -> { where(accept_finance_buyers: true) }
  scope :allows_direct_contact, -> { where(allow_direct_contact: true) }
  scope :allows_viewings, -> { where(allow_scheduled_viewings: true) }

  # Settlement period helpers
  def settlement_days
    case preferred_settlement_period
    when "asap" then 30
    when "standard" then 42
    when "flexible" then 90
    when "specific" then days_until_specific_date
    end
  end

  def settlement_description
    case preferred_settlement_period
    when "asap" then "As soon as possible (30 days)"
    when "standard" then "Standard (42-45 days)"
    when "flexible" then "Flexible (up to 90 days)"
    when "specific" then "Specific date: #{specific_settlement_date&.strftime('%d %B %Y')}"
    end
  end

  # Buyer acceptance helpers
  def accepts_buyer_finance_type?(finance_status)
    case finance_status
    when "cash" then accept_cash_buyers?
    when "pre_approved" then accept_pre_approved_buyers?
    when "needs_finance" then accept_finance_buyers?
    else true # Exploring buyers are generally acceptable
    end
  end

  def accepted_finance_types
    types = []
    types << "cash" if accept_cash_buyers?
    types << "pre_approved" if accept_pre_approved_buyers?
    types << "needs_finance" if accept_finance_buyers?
    types
  end

  # Viewing availability helpers
  def available_weekdays?
    viewing_availability["weekdays"]
  end

  def available_weekends?
    viewing_availability["weekends"]
  end

  def available_times
    viewing_availability["times"] || []
  end

  def available_morning?
    available_times.include?("morning")
  end

  def available_afternoon?
    available_times.include?("afternoon")
  end

  def available_evening?
    available_times.include?("evening")
  end

  private

  def days_until_specific_date
    return nil unless specific_settlement_date

    (specific_settlement_date - Date.current).to_i
  end
end
