# frozen_string_literal: true

class JourneyChecklist < ApplicationRecord
  JOURNEY_TYPES = %w[buyer seller service_provider].freeze

  has_many :checklist_items, -> { order(:position) }, dependent: :destroy

  validates :journey_type, presence: true, inclusion: { in: JOURNEY_TYPES }
  validates :name, presence: true

  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(journey_type: type) }
  scope :ordered, -> { order(:position) }

  # Scopes for each journey type
  scope :buyer, -> { by_type("buyer") }
  scope :seller, -> { by_type("seller") }
  scope :service_provider, -> { by_type("service_provider") }

  def buyer?
    journey_type == "buyer"
  end

  def seller?
    journey_type == "seller"
  end

  def service_provider?
    journey_type == "service_provider"
  end

  def total_points
    checklist_items.sum(:points)
  end

  def item_count
    checklist_items.count
  end

  # Get all checklists for a journey type
  def self.for_journey(type)
    active.by_type(type).ordered.includes(:checklist_items)
  end
end
