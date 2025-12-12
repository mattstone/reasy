# frozen_string_literal: true

class ReviewDispute < ApplicationRecord
  include Auditable

  # Dispute reasons
  REASONS = %w[false_information inappropriate_content wrong_person harassment other].freeze

  # Dispute statuses
  STATUSES = %w[pending under_review upheld rejected].freeze

  belongs_to :review
  belongs_to :disputed_by, class_name: "User"
  belongs_to :resolved_by, class_name: "User", optional: true

  validates :reason, presence: true, inclusion: { in: REASONS }
  validates :explanation, presence: true, length: { minimum: 20, maximum: 2000 }
  validates :status, inclusion: { in: STATUSES }

  validate :cannot_dispute_own_review
  validate :review_not_already_disputed

  # Callbacks
  after_create :mark_review_disputed

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :under_review, -> { where(status: "under_review") }
  scope :upheld, -> { where(status: "upheld") }
  scope :rejected, -> { where(status: "rejected") }
  scope :unresolved, -> { where(status: %w[pending under_review]) }
  scope :resolved, -> { where(status: %w[upheld rejected]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :requiring_action, -> { pending }

  # Status helpers
  def pending?
    status == "pending"
  end

  def under_review?
    status == "under_review"
  end

  def upheld?
    status == "upheld"
  end

  def rejected?
    status == "rejected"
  end

  def resolved?
    upheld? || rejected?
  end

  # Status transitions
  def start_review!
    return false unless pending?

    update!(status: "under_review")
  end

  def uphold!(admin:, notes: nil)
    return false unless can_resolve?

    transaction do
      update!(
        status: "upheld",
        resolved_by: admin,
        resolved_at: Time.current,
        resolution_notes: notes
      )

      # Remove the review
      review.remove!(admin_notes: "Removed due to upheld dispute: #{reason}")
    end
  end

  def reject!(admin:, notes: nil)
    return false unless can_resolve?

    transaction do
      update!(
        status: "rejected",
        resolved_by: admin,
        resolved_at: Time.current,
        resolution_notes: notes
      )

      # Republish the review if it was held due to dispute
      review.publish! if review.disputed?
    end
  end

  def can_resolve?
    pending? || under_review?
  end

  # Evidence helpers
  def add_evidence!(description:, url: nil, file_data: nil)
    new_evidence = evidence + [{
      "description" => description,
      "url" => url,
      "file_data" => file_data,
      "added_at" => Time.current.iso8601
    }]
    update!(evidence: new_evidence)
  end

  def evidence_count
    evidence.size
  end

  def has_evidence?
    evidence.present?
  end

  # Reason display
  def reason_display
    reason.titleize.gsub("_", " ")
  end

  private

  def cannot_dispute_own_review
    return unless disputed_by_id == review&.reviewer_id

    errors.add(:disputed_by, "cannot dispute their own review")
  end

  def review_not_already_disputed
    return unless review&.has_active_dispute?

    errors.add(:review, "already has an active dispute")
  end

  def mark_review_disputed
    review.mark_disputed!
  end
end
