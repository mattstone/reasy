# frozen_string_literal: true

class Review < ApplicationRecord
  include SoftDeletable
  include Auditable

  # Reviewee roles
  REVIEWEE_ROLES = %w[buyer seller service_provider].freeze

  # Review statuses
  STATUSES = %w[pending held published removed disputed].freeze

  # Rating categories by role
  CATEGORY_RATINGS = {
    buyer: %w[communication reliability responsiveness],
    seller: %w[communication honesty property_accuracy responsiveness],
    service_provider: %w[communication professionalism quality timeliness value]
  }.freeze

  # Hold duration for negative reviews (2 stars or below)
  NEGATIVE_REVIEW_HOLD_HOURS = 48

  belongs_to :reviewer, class_name: "User"
  belongs_to :reviewee, class_name: "User"

  has_many :review_disputes, dependent: :destroy

  validates :reviewee_role, presence: true, inclusion: { in: REVIEWEE_ROLES }
  validates :overall_rating, presence: true, numericality: { in: 1..5 }
  validates :body, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :status, inclusion: { in: STATUSES }
  validates :title, length: { maximum: 100 }, allow_blank: true
  validates :public_response, length: { maximum: 1000 }, allow_blank: true

  validate :reviewer_cannot_review_self
  validate :valid_category_ratings

  # Callbacks
  before_validation :set_initial_status, on: :create
  after_create :notify_parties

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :held, -> { where(status: "held") }
  scope :published, -> { where(status: "published") }
  scope :removed, -> { where(status: "removed") }
  scope :disputed, -> { where(status: "disputed") }
  scope :awaiting_moderation, -> { where(status: %w[pending held]) }
  scope :negative, -> { where("overall_rating <= ?", 2) }
  scope :positive, -> { where("overall_rating >= ?", 4) }
  scope :for_buyers, -> { where(reviewee_role: "buyer") }
  scope :for_sellers, -> { where(reviewee_role: "seller") }
  scope :for_service_providers, -> { where(reviewee_role: "service_provider") }
  scope :recent, -> { order(created_at: :desc) }
  scope :hold_expired, -> { held.where("hold_until <= ?", Time.current) }

  # Status helpers
  def pending?
    status == "pending"
  end

  def held?
    status == "held"
  end

  def published?
    status == "published"
  end

  def removed?
    status == "removed"
  end

  def disputed?
    status == "disputed"
  end

  def negative?
    overall_rating.present? && overall_rating <= 2
  end

  def positive?
    overall_rating >= 4
  end

  def neutral?
    overall_rating == 3
  end

  # Hold management
  def on_hold?
    held? && hold_until.present? && hold_until > Time.current
  end

  def hold_expired?
    held? && hold_until.present? && hold_until <= Time.current
  end

  def hours_until_release
    return nil unless on_hold?

    ((hold_until - Time.current) / 1.hour).ceil
  end

  # Status transitions
  def publish!
    return false unless can_publish?

    update!(status: "published")
  end

  def hold!(reason: nil)
    update!(
      status: "held",
      hold_until: NEGATIVE_REVIEW_HOLD_HOURS.hours.from_now,
      hold_reason: reason || "Negative review - 48 hour review period"
    )
  end

  def remove!(admin_notes: nil)
    update!(
      status: "removed",
      admin_notes: admin_notes
    )
  end

  def mark_disputed!
    update!(status: "disputed")
  end

  def can_publish?
    pending? || (held? && hold_expired?)
  end

  # Public response
  def add_response!(response_text)
    update!(
      public_response: response_text,
      public_response_at: Time.current
    )
  end

  def has_response?
    public_response.present?
  end

  # Category rating helpers
  def category_rating(category)
    category_ratings[category.to_s]
  end

  def available_categories
    CATEGORY_RATINGS[reviewee_role.to_sym] || []
  end

  # Star display helpers
  def stars_display
    "★" * overall_rating + "☆" * (5 - overall_rating)
  end

  # Dispute helpers
  def has_active_dispute?
    review_disputes.where(status: %w[pending under_review]).exists?
  end

  def latest_dispute
    review_disputes.order(created_at: :desc).first
  end

  private

  def set_initial_status
    self.status = if negative?
      self.hold_until = NEGATIVE_REVIEW_HOLD_HOURS.hours.from_now
      self.hold_reason = "Automatic hold for negative review"
      "held"
    else
      "published"
    end
  end

  def reviewer_cannot_review_self
    return unless reviewer_id == reviewee_id

    errors.add(:reviewer, "cannot review themselves")
  end

  def valid_category_ratings
    return if category_ratings.blank?

    available = available_categories
    category_ratings.each do |category, rating|
      unless available.include?(category)
        errors.add(:category_ratings, "#{category} is not a valid category for #{reviewee_role}")
      end
      unless rating.is_a?(Integer) && rating.between?(1, 5)
        errors.add(:category_ratings, "#{category} rating must be between 1 and 5")
      end
    end
  end

  def notify_parties
    # TODO: Implement notification system
    # NotificationJob.perform_later(:review_received, reviewee, self)
    # NotificationJob.perform_later(:review_submitted, reviewer, self) if held?
  end
end
