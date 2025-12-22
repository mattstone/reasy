# frozen_string_literal: true

class UserChecklistProgress < ApplicationRecord
  STATUSES = %w[pending in_progress completed skipped].freeze

  belongs_to :user
  belongs_to :checklist_item
  belongs_to :context, polymorphic: true, optional: true

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :checklist_item_id, uniqueness: {
    scope: [:user_id, :context_type, :context_id],
    message: "progress already exists for this item"
  }

  scope :pending, -> { where(status: "pending") }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed") }
  scope :skipped, -> { where(status: "skipped") }
  scope :active, -> { where(status: %w[pending in_progress]) }
  scope :finished, -> { where(status: %w[completed skipped]) }
  scope :for_journey, ->(type) { joins(checklist_item: :journey_checklist).where(journey_checklists: { journey_type: type }) }
  scope :chronological, -> { order(:created_at) }
  scope :recently_completed, -> { completed.order(completed_at: :desc) }

  delegate :title, :description, :points, :category, :key, to: :checklist_item
  delegate :journey_type, :journey_checklist, to: :checklist_item

  # Status helpers
  def pending?
    status == "pending"
  end

  def in_progress?
    status == "in_progress"
  end

  def completed?
    status == "completed"
  end

  def skipped?
    status == "skipped"
  end

  def started?
    started_at.present?
  end

  def finished?
    completed? || skipped?
  end

  # State transitions
  def start!
    return if started?

    update!(
      status: "in_progress",
      started_at: Time.current
    )
  end

  def complete!(notes: nil)
    return if completed?

    update!(
      status: "completed",
      completed_at: Time.current,
      notes: notes
    )

    # Award points to user
    award_points!
  end

  def skip!(notes: nil)
    return if skipped?

    update!(
      status: "skipped",
      completed_at: Time.current,
      notes: notes
    )
  end

  def reset!
    update!(
      status: "pending",
      started_at: nil,
      completed_at: nil
    )
  end

  # Duration helpers
  def duration_seconds
    return nil unless completed? && started_at && completed_at
    (completed_at - started_at).to_i
  end

  def duration_minutes
    return nil unless duration_seconds
    duration_seconds / 60.0
  end

  def duration_display
    return nil unless duration_seconds

    if duration_seconds < 60
      "#{duration_seconds} seconds"
    elsif duration_seconds < 3600
      "#{(duration_seconds / 60).round} minutes"
    else
      hours = duration_seconds / 3600
      minutes = (duration_seconds % 3600) / 60
      "#{hours}h #{minutes}m"
    end
  end

  private

  def award_points!
    return unless completed?

    user.increment!(:journey_points, checklist_item.points)
    user.recalculate_level!
  end
end
