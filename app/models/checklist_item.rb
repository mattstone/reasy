# frozen_string_literal: true

class ChecklistItem < ApplicationRecord
  CATEGORIES = %w[pre_offer property_evaluation offer due_diligence settlement pre_listing listing service_delivery].freeze

  belongs_to :journey_checklist
  has_many :user_checklist_progresses, dependent: :destroy

  validates :key, presence: true, uniqueness: { scope: :journey_checklist_id }
  validates :title, presence: true
  validates :points, numericality: { greater_than_or_equal_to: 0 }
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true

  scope :ordered, -> { order(:position) }
  scope :by_category, ->(category) { where(category: category) }
  scope :requiring_document, -> { where(requires_document: true) }
  scope :requiring_service_provider, -> { where(requires_service_provider: true) }

  delegate :journey_type, to: :journey_checklist

  def requires_document?
    requires_document
  end

  def requires_service_provider?
    requires_service_provider
  end

  # Check if this item is blocked by another item
  def blocked_by?(user, context = nil)
    return false if required_for_next.blank?

    blocking_item = journey_checklist.checklist_items.find_by(key: required_for_next)
    return false unless blocking_item

    progress = blocking_item.progress_for(user, context)
    progress.nil? || !progress.completed?
  end

  # Get user's progress on this item
  def progress_for(user, context = nil)
    scope = user_checklist_progresses.where(user: user)
    if context
      scope.find_by(context: context)
    else
      scope.where(context_type: nil, context_id: nil).first
    end
  end

  # Check if item is completed for user
  def completed_by?(user, context = nil)
    progress_for(user, context)&.completed? || false
  end

  # Start progress on this item
  def start_for(user, context = nil)
    progress = find_or_create_progress(user, context)
    progress.start! unless progress.started?
    progress
  end

  # Complete this item for a user
  def complete_for(user, context = nil, notes: nil)
    progress = find_or_create_progress(user, context)
    progress.complete!(notes: notes)
    progress
  end

  private

  def find_or_create_progress(user, context)
    UserChecklistProgress.find_or_create_by!(
      user: user,
      checklist_item: self,
      context: context
    )
  end
end
