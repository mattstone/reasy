# frozen_string_literal: true

class TransactionMilestone < ApplicationRecord
  MILESTONE_TYPES = %w[
    contract_prepared
    offer_accepted
    finance_approved
    building_inspection_passed
    pest_inspection_passed
    conditions_satisfied
    deposit_paid
    cooling_off_complete
    settlement_date_confirmed
    pre_settlement_inspection
    keys_ready
    settlement_complete
  ].freeze

  VISIBILITY_OPTIONS = %w[buyer seller both].freeze

  belongs_to :property_transaction, class_name: "Transaction", foreign_key: :transaction_id
  belongs_to :completed_by, class_name: "User", optional: true

  validates :milestone_type, presence: true, inclusion: { in: MILESTONE_TYPES }
  validates :title, presence: true
  validates :visible_to, presence: true, inclusion: { in: VISIBILITY_OPTIONS }
  validates :milestone_type, uniqueness: { scope: :transaction_id }

  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending, -> { where(completed_at: nil) }
  scope :visible_to_buyer, -> { where(visible_to: %w[buyer both]) }
  scope :visible_to_seller, -> { where(visible_to: %w[seller both]) }
  scope :chronological, -> { order(:completed_at) }
  scope :recent, -> { order(completed_at: :desc) }

  delegate :buyer, :seller, :property, to: :property_transaction

  # Status helpers
  def completed?
    completed_at.present?
  end

  def pending?
    completed_at.nil?
  end

  # Visibility helpers
  def visible_to_buyer?
    visible_to.in?(%w[buyer both])
  end

  def visible_to_seller?
    visible_to.in?(%w[seller both])
  end

  def visible_to_user?(user)
    return true if visible_to == "both"

    if property_transaction.buyer == user
      visible_to_buyer?
    elsif property_transaction.seller == user
      visible_to_seller?
    else
      false
    end
  end

  # Complete this milestone
  def complete!(by_user: nil)
    update!(
      completed_at: Time.current,
      completed_by: by_user
    )
  end

  # Create standard milestones for a transaction
  def self.create_standard_milestones!(property_transaction)
    milestones = [
      { type: "contract_prepared", title: "Contract Prepared", visible: "seller" },
      { type: "offer_accepted", title: "Offer Accepted", visible: "both" },
      { type: "finance_approved", title: "Finance Approved", visible: "both" },
      { type: "building_inspection_passed", title: "Building Inspection Passed", visible: "both" },
      { type: "pest_inspection_passed", title: "Pest Inspection Passed", visible: "both" },
      { type: "conditions_satisfied", title: "All Conditions Satisfied", visible: "both" },
      { type: "deposit_paid", title: "Deposit Paid", visible: "both" },
      { type: "cooling_off_complete", title: "Cooling-Off Period Complete", visible: "both" },
      { type: "settlement_date_confirmed", title: "Settlement Date Confirmed", visible: "both" },
      { type: "pre_settlement_inspection", title: "Pre-Settlement Inspection Scheduled", visible: "both" },
      { type: "keys_ready", title: "Keys Ready for Handover", visible: "seller" },
      { type: "settlement_complete", title: "Settlement Complete", visible: "both" }
    ]

    milestones.each do |m|
      create!(
        property_transaction: property_transaction,
        milestone_type: m[:type],
        title: m[:title],
        visible_to: m[:visible]
      )
    end
  end

  # Get milestones visible to a specific user
  def self.visible_to(user, transaction)
    if transaction.buyer == user
      transaction.transaction_milestones.visible_to_buyer
    elsif transaction.seller == user
      transaction.transaction_milestones.visible_to_seller
    else
      none
    end
  end

  # Progress calculation
  def self.completion_percentage(transaction)
    total = transaction.transaction_milestones.count
    return 0 if total.zero?

    completed = transaction.transaction_milestones.completed.count
    (completed.to_f / total * 100).round
  end

  # Display helpers
  def icon
    icons = {
      "contract_prepared" => "📝",
      "offer_accepted" => "🤝",
      "finance_approved" => "💰",
      "building_inspection_passed" => "🏠",
      "pest_inspection_passed" => "🐜",
      "conditions_satisfied" => "✅",
      "deposit_paid" => "💵",
      "cooling_off_complete" => "❄️",
      "settlement_date_confirmed" => "📅",
      "pre_settlement_inspection" => "🔍",
      "keys_ready" => "🔑",
      "settlement_complete" => "🎉"
    }
    icons[milestone_type] || "📌"
  end
end
