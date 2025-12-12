# frozen_string_literal: true

class ProviderJob < ApplicationRecord
  include Auditable

  # Status values
  STATUSES = %w[pending scheduled in_progress completed cancelled].freeze

  # Associations
  belongs_to :service_provider_profile
  belongs_to :provider_lead, optional: true
  belongs_to :property, optional: true
  belongs_to :client, class_name: "User"
  belongs_to :property_transaction, class_name: "Transaction", foreign_key: "transaction_id", optional: true

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :service_type, presence: true, inclusion: { in: ServiceProviderProfile::SERVICE_TYPES }
  validates :title, presence: true
  validates :client_rating, numericality: { in: 1..5 }, allow_nil: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { where(status: "pending") }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :active, -> { where(status: %w[pending scheduled in_progress]) }
  scope :upcoming, -> { where("scheduled_date >= ?", Date.current).order(scheduled_date: :asc) }
  scope :past_due, -> { where("scheduled_date < ?", Date.current).where(status: %w[pending scheduled]) }
  scope :by_service_type, ->(type) { where(service_type: type) }
  scope :rated, -> { where.not(client_rating: nil) }

  # Status transitions
  def schedule!(date)
    update!(status: "scheduled", scheduled_date: date)
  end

  def start!
    update!(status: "in_progress", started_at: Time.current)
  end

  def complete!(notes: nil, final_price_cents: nil)
    attrs = { status: "completed", completed_at: Time.current }
    attrs[:completion_notes] = notes if notes.present?
    attrs[:final_price_cents] = final_price_cents if final_price_cents.present?
    update!(attrs)
  end

  def cancel!
    update!(status: "cancelled")
  end

  def rate!(rating, review = nil)
    update!(client_rating: rating, client_review: review)
  end

  # Status helpers
  def pending?
    status == "pending"
  end

  def scheduled?
    status == "scheduled"
  end

  def in_progress?
    status == "in_progress"
  end

  def completed?
    status == "completed"
  end

  def cancelled?
    status == "cancelled"
  end

  def active?
    status.in?(%w[pending scheduled in_progress])
  end

  def closed?
    status.in?(%w[completed cancelled])
  end

  def past_due?
    scheduled_date.present? && scheduled_date < Date.current && active?
  end

  def rated?
    client_rating.present?
  end

  # Display helpers
  def status_badge_class
    case status
    when "pending"
      "badge-orange"
    when "scheduled"
      "badge-blue"
    when "in_progress"
      "badge-purple"
    when "completed"
      "badge-green"
    when "cancelled"
      "badge-red"
    else
      "badge-gray"
    end
  end

  def quoted_price
    return nil unless quoted_price_cents

    quoted_price_cents / 100.0
  end

  def final_price
    return nil unless final_price_cents

    final_price_cents / 100.0
  end

  def price_display
    price = final_price || quoted_price
    return "Not quoted" unless price

    "$#{price.round(2)}"
  end

  def provider
    service_provider_profile
  end

  def duration
    return nil unless started_at && completed_at

    completed_at - started_at
  end
end
