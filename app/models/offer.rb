# frozen_string_literal: true

class Offer < ApplicationRecord
  include SoftDeletable
  include Auditable

  FINANCE_TYPES = %w[cash pre_approved subject_to_finance].freeze
  STATUSES = %w[draft submitted viewed countered accepted rejected withdrawn expired].freeze

  # Default offer validity in days
  DEFAULT_EXPIRY_DAYS = 5

  # Associations
  belongs_to :property, counter_cache: :offer_count
  belongs_to :buyer, class_name: "User"
  belongs_to :buyer_entity, class_name: "Entity", optional: true
  belongs_to :counter_offer, class_name: "Offer", optional: true

  has_one :property_transaction, class_name: "Transaction", dependent: :nullify
  has_many :counter_offers, class_name: "Offer", foreign_key: :counter_offer_id, dependent: :nullify

  # Validations
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :finance_type, presence: true, inclusion: { in: FINANCE_TYPES }
  validates :settlement_days, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :buyer_cannot_be_seller
  validate :property_must_be_active, on: :create

  # Callbacks
  before_create :set_expiry_date

  # Scopes
  scope :active, -> { where(status: %w[submitted viewed]) }
  scope :pending, -> { where(status: %w[draft submitted]) }
  scope :responded, -> { where(status: %w[countered accepted rejected]) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(submitted_at: :desc) }
  scope :expiring_soon, -> { where("expires_at <= ?", 24.hours.from_now).where(status: %w[submitted viewed]) }
  scope :expired_unprocessed, -> { where("expires_at < ?", Time.current).where(status: %w[submitted viewed]) }

  # Amount helpers
  def amount
    return nil unless amount_cents

    amount_cents / 100.0
  end

  def amount=(value)
    self.amount_cents = value.present? ? (value.to_f * 100).to_i : nil
  end

  def deposit
    return nil unless deposit_cents

    deposit_cents / 100.0
  end

  def deposit=(value)
    self.deposit_cents = value.present? ? (value.to_f * 100).to_i : nil
  end

  # Status helpers
  def draft?
    status == "draft"
  end

  def submitted?
    status == "submitted"
  end

  def viewed?
    status == "viewed"
  end

  def countered?
    status == "countered"
  end

  def accepted?
    status == "accepted"
  end

  def rejected?
    status == "rejected"
  end

  def withdrawn?
    status == "withdrawn"
  end

  def expired?
    status == "expired" || (expires_at.present? && expires_at < Time.current && !finalized?)
  end

  def finalized?
    status.in?(%w[accepted rejected withdrawn expired])
  end

  def active?
    status.in?(%w[submitted viewed])
  end

  # Finance helpers
  def cash?
    finance_type == "cash"
  end

  def pre_approved?
    finance_type == "pre_approved"
  end

  def finance_subject_to_approval?
    finance_type == "subject_to_finance"
  end

  def has_conditions?
    subject_to_finance? || subject_to_building_inspection? ||
      subject_to_pest_inspection? || subject_to_valuation? ||
      subject_to_sale_of_property? || other_conditions.present?
  end

  # Note: subject_to_finance? is an attribute accessor from the boolean column

  def conditions_list
    conditions = []
    conditions << "Finance" if subject_to_finance?
    conditions << "Building Inspection" if subject_to_building_inspection?
    conditions << "Pest Inspection" if subject_to_pest_inspection?
    conditions << "Valuation" if subject_to_valuation?
    conditions << "Sale of Property" if subject_to_sale_of_property?
    conditions << "Other: #{other_conditions}" if other_conditions.present?
    conditions
  end

  # Status transitions
  def submit!
    return false unless draft?

    update!(
      status: "submitted",
      submitted_at: Time.current
    )
  end

  def mark_viewed!
    return false unless submitted?

    update!(
      status: "viewed",
      viewed_at: Time.current
    )
  end

  def accept!(seller_response: nil)
    return false unless active?

    ActiveRecord::Base.transaction do
      update!(
        status: "accepted",
        accepted_at: Time.current,
        responded_at: Time.current,
        seller_response: seller_response
      )

      property.mark_under_offer!

      # Create transaction
      Transaction.create!(
        property: property,
        offer: self,
        seller: property.user,
        buyer: buyer,
        seller_entity: property.entity,
        buyer_entity: buyer_entity,
        sale_price_cents: amount_cents,
        deposit_cents: deposit_cents,
        settlement_date: settlement_days.days.from_now.to_date
      )
    end
  end

  def reject!(seller_response: nil)
    return false unless active?

    update!(
      status: "rejected",
      rejected_at: Time.current,
      responded_at: Time.current,
      seller_response: seller_response
    )
  end

  def counter!(counter_amount_cents:, **options)
    return false unless active?

    ActiveRecord::Base.transaction do
      update!(
        status: "countered",
        responded_at: Time.current
      )

      counter_offers.create!(
        property: property,
        buyer: property.user, # Seller becomes "buyer" in counter-offer
        buyer_entity: property.entity,
        amount_cents: counter_amount_cents,
        finance_type: finance_type,
        settlement_days: options[:settlement_days] || settlement_days,
        subject_to_finance: options.fetch(:subject_to_finance, subject_to_finance?),
        subject_to_building_inspection: options.fetch(:subject_to_building_inspection, subject_to_building_inspection?),
        subject_to_pest_inspection: options.fetch(:subject_to_pest_inspection, subject_to_pest_inspection?),
        counter_offer: self,
        status: "submitted",
        submitted_at: Time.current
      )
    end
  end

  def withdraw!
    return false if finalized?

    update!(
      status: "withdrawn",
      withdrawn_at: Time.current
    )
  end

  def expire!
    return false unless active?
    return false unless expires_at.present? && expires_at < Time.current

    update!(status: "expired")
  end

  # Class methods
  def self.expire_overdue!
    expired_unprocessed.find_each(&:expire!)
  end

  private

  def buyer_cannot_be_seller
    # Skip validation for counter-offers (where seller becomes the buyer)
    return if counter_offer.present?
    return unless property&.user == buyer

    errors.add(:buyer, "cannot make an offer on their own property")
  end

  def property_must_be_active
    return unless property
    return if property.can_receive_offers?

    errors.add(:property, "is not accepting offers")
  end

  def set_expiry_date
    self.expires_at ||= DEFAULT_EXPIRY_DAYS.days.from_now
  end
end
