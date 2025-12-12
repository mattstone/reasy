# frozen_string_literal: true

class TransactionEvent < ApplicationRecord
  EVENT_TYPES = %w[
    created
    exchanged
    cooling_off_started
    cooling_off_ended
    unconditional
    settling
    settled
    fallen_through
    finance_approved
    building_inspection_passed
    pest_inspection_passed
    deposit_paid
    document_uploaded
    conveyancer_assigned
    custom
  ].freeze

  belongs_to :property_transaction, class_name: "Transaction", foreign_key: "transaction_id"
  belongs_to :user, optional: true

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :title, presence: true
  validates :occurred_at, presence: true

  scope :recent, -> { order(occurred_at: :desc) }
  scope :chronological, -> { order(occurred_at: :asc) }
  scope :by_type, ->(type) { where(event_type: type) }

  def custom?
    event_type == "custom"
  end

  def milestone?
    event_type.in?(%w[exchanged unconditional settled fallen_through])
  end
end
