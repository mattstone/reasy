# frozen_string_literal: true

class PropertyEnquiry < ApplicationRecord
  include Auditable

  STATUSES = %w[pending responded archived].freeze

  belongs_to :property, counter_cache: :enquiry_count
  belongs_to :user
  belongs_to :entity, optional: true

  validates :message, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :responded, -> { where(status: "responded") }
  scope :archived, -> { where(status: "archived") }
  scope :recent, -> { order(created_at: :desc) }

  def pending?
    status == "pending"
  end

  def responded?
    status == "responded"
  end

  def respond!(response_text)
    update!(
      response: response_text,
      responded_at: Time.current,
      status: "responded"
    )
  end

  def archive!
    update!(status: "archived")
  end
end
