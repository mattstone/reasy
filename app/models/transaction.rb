# frozen_string_literal: true

class Transaction < ApplicationRecord
  include Auditable

  STATUSES = %w[pending exchanged cooling_off unconditional settling settled fallen_through].freeze

  # NSW cooling-off period is 5 business days
  COOLING_OFF_BUSINESS_DAYS = 5

  # Associations
  belongs_to :property
  belongs_to :offer
  belongs_to :seller, class_name: "User"
  belongs_to :buyer, class_name: "User"
  belongs_to :seller_entity, class_name: "Entity", optional: true
  belongs_to :buyer_entity, class_name: "Entity", optional: true
  belongs_to :buyer_conveyancer, class_name: "User", optional: true
  belongs_to :seller_conveyancer, class_name: "User", optional: true

  has_many :transaction_events, dependent: :destroy

  # Validations
  validates :sale_price_cents, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }

  # Scopes
  scope :active, -> { where(status: %w[pending exchanged cooling_off unconditional settling]) }
  scope :completed, -> { where(status: "settled") }
  scope :failed, -> { where(status: "fallen_through") }
  scope :in_cooling_off, -> { where(status: "cooling_off") }
  scope :settling_soon, -> { where("settlement_date <= ?", 7.days.from_now).where(status: %w[unconditional settling]) }
  scope :recent, -> { order(created_at: :desc) }

  # Amount helpers
  def sale_price
    return nil unless sale_price_cents

    sale_price_cents / 100.0
  end

  def deposit
    return nil unless deposit_cents

    deposit_cents / 100.0
  end

  def deposit_paid
    return nil unless deposit_paid_cents

    deposit_paid_cents / 100.0
  end

  def deposit_outstanding?
    return false unless deposit_cents

    (deposit_paid_cents || 0) < deposit_cents
  end

  def deposit_remaining_cents
    return 0 unless deposit_cents

    deposit_cents - (deposit_paid_cents || 0)
  end

  # Status helpers
  def pending?
    status == "pending"
  end

  def exchanged?
    status == "exchanged"
  end

  def in_cooling_off?
    status == "cooling_off"
  end

  def unconditional?
    status == "unconditional"
  end

  def settling?
    status == "settling"
  end

  def settled?
    status == "settled"
  end

  def fallen_through?
    status == "fallen_through"
  end

  def active?
    !settled? && !fallen_through?
  end

  def disputed?
    # Placeholder - disputes feature not yet implemented
    false
  end

  def can_rescind?
    in_cooling_off? && cooling_off_ends_at.present? && cooling_off_ends_at > Time.current
  end

  # Progress tracking
  def all_conditions_satisfied?
    satisfied = true
    satisfied &&= finance_approved? if offer.subject_to_finance?
    satisfied &&= building_inspection_passed? if offer.subject_to_building_inspection?
    satisfied &&= pest_inspection_passed? if offer.subject_to_pest_inspection?
    satisfied
  end

  def days_until_settlement
    return nil unless settlement_date

    (settlement_date - Date.current).to_i
  end

  def overdue?
    settlement_date.present? && settlement_date < Date.current && !settled? && !fallen_through?
  end

  # Status transitions
  def exchange!(exchange_date: Date.current)
    return false unless pending?

    update!(
      status: "exchanged",
      exchange_date: exchange_date
    )
    log_event!("exchanged", "Contracts exchanged")
  end

  def start_cooling_off!(ends_at: nil)
    return false unless exchanged?

    cooling_off_end = ends_at || calculate_cooling_off_end

    update!(
      status: "cooling_off",
      cooling_off_ends_at: cooling_off_end
    )
    log_event!("cooling_off_started", "Cooling-off period started", metadata: { ends_at: cooling_off_end })
  end

  def go_unconditional!
    return false unless in_cooling_off? || (exchanged? && offer.cooling_off_waived?)

    update!(status: "unconditional")
    log_event!("unconditional", "Transaction is now unconditional")
  end

  def start_settling!
    return false unless unconditional?
    return false unless all_conditions_satisfied?

    update!(status: "settling")
    log_event!("settling", "Settlement process started")
  end

  def settle!
    return false unless settling? || unconditional?

    ActiveRecord::Base.transaction do
      update!(
        status: "settled",
        settled_at: Time.current
      )
      property.mark_sold!(sale_price_cents: sale_price_cents)
      log_event!("settled", "Property has settled", metadata: { sale_price_cents: sale_price_cents })
    end
  end

  def fall_through!(reason:)
    return false if settled?

    ActiveRecord::Base.transaction do
      update!(
        status: "fallen_through",
        fallen_through_at: Time.current,
        fallen_through_reason: reason
      )
      property.update!(status: "active") if property.under_offer?
      log_event!("fallen_through", "Transaction has fallen through", metadata: { reason: reason })
    end
  end

  def rescind!(reason: "Buyer exercised cooling-off rights")
    return false unless can_rescind?

    fall_through!(reason: reason)
  end

  # Condition satisfaction
  def approve_finance!
    return if finance_approved?

    update!(
      finance_approved: true,
      finance_approved_at: Time.current
    )
    log_event!("finance_approved", "Finance has been approved")
    check_conditions_complete!
  end

  def pass_building_inspection!
    return if building_inspection_passed?

    update!(
      building_inspection_passed: true,
      building_inspection_at: Time.current
    )
    log_event!("building_inspection_passed", "Building inspection passed")
    check_conditions_complete!
  end

  def pass_pest_inspection!
    return if pest_inspection_passed?

    update!(
      pest_inspection_passed: true,
      pest_inspection_at: Time.current
    )
    log_event!("pest_inspection_passed", "Pest inspection passed")
    check_conditions_complete!
  end

  def record_deposit_payment!(amount_cents)
    self.deposit_paid_cents = (deposit_paid_cents || 0) + amount_cents
    save!
    log_event!("deposit_paid", "Deposit payment received", metadata: { amount_cents: amount_cents, total_paid_cents: deposit_paid_cents })
  end

  # Helpers
  def log_event!(event_type, title, description: nil, metadata: {})
    transaction_events.create!(
      event_type: event_type,
      title: title,
      description: description,
      metadata: metadata,
      occurred_at: Time.current,
      user: Current.user
    )
  end

  private

  def calculate_cooling_off_end
    # NSW: 5 business days from exchange
    business_days = 0
    date = exchange_date || Date.current

    while business_days < COOLING_OFF_BUSINESS_DAYS
      date += 1.day
      business_days += 1 unless date.saturday? || date.sunday?
    end

    date.end_of_day
  end

  def check_conditions_complete!
    return unless all_conditions_satisfied? && in_cooling_off?

    # Automatically progress if cooling-off has ended and conditions are met
    go_unconditional! if cooling_off_ends_at.present? && cooling_off_ends_at < Time.current
  end
end
