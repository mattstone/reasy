# frozen_string_literal: true

class ServiceProviderProfile < ApplicationRecord
  include SoftDeletable
  include Auditable

  # Service types
  SERVICE_TYPES = %w[
    conveyancer solicitor building_inspector pest_inspector
    mortgage_broker financial_advisor accountant
    removalist cleaner photographer videographer
    home_stager gardener handyman electrician plumber
  ].freeze

  # Verification statuses
  VERIFICATION_STATUSES = %w[pending submitted under_review verified rejected].freeze

  # Response time options
  RESPONSE_TIMES = %w[same_day 24_hours 48_hours 3_days].freeze

  # Common differentiators
  DIFFERENTIATORS = %w[
    same_day_response available_weekends same_day_reports
    free_consultation fixed_pricing online_booking
    after_hours_available emergency_service
  ].freeze

  belongs_to :user
  has_many :provider_leads, dependent: :destroy
  has_many :provider_jobs, dependent: :destroy

  # Aliases for view compatibility
  def tagline
    headline
  end

  def bio
    description
  end

  def phone
    business_phone
  end

  def website
    # No website column - could add later
    nil
  end

  def years_experience
    # No years_experience column - could add later
    nil
  end

  validates :business_name, presence: true
  validates :service_type, presence: true, inclusion: { in: SERVICE_TYPES }
  validates :verification_status, inclusion: { in: VERIFICATION_STATUSES }
  validates :response_time_commitment, inclusion: { in: RESPONSE_TIMES }, allow_blank: true
  validates :abn, format: { with: /\A\d{11}\z/, message: "must be 11 digits" }, allow_blank: true
  # These validations are for AI voice settings columns which don't exist on this model
  # validates :tone_level, numericality: { in: 1..10 }, allow_nil: true
  # validates :warmth_level, numericality: { in: 1..10 }, allow_nil: true
  # validates :detail_level, numericality: { in: 1..10 }, allow_nil: true

  # Scopes
  scope :verified, -> { where(verification_status: "verified") }
  scope :accepting_clients, -> { where(accepting_new_clients: true) }
  scope :featured, -> { where(featured: true).where("featured_until IS NULL OR featured_until > ?", Time.current) }
  scope :by_service_type, ->(type) { where(service_type: type) }
  scope :by_area, ->(area) { where("? = ANY(service_areas)", area) }
  scope :top_rated, -> { order(average_rating: :desc, total_reviews: :desc) }

  # Verification helpers
  def verified?
    verification_status == "verified"
  end

  def pending_verification?
    verification_status == "pending"
  end

  def can_accept_leads?
    verified? && accepting_new_clients?
  end

  # Rating helpers
  def rating_display
    return "New" unless average_rating

    "%.1f" % average_rating
  end

  def has_reviews?
    total_reviews.positive?
  end

  def update_rating_stats!
    reviews = user.reviews_received.published.where(reviewee_role: "service_provider")
    update!(
      average_rating: reviews.average(:overall_rating),
      total_reviews: reviews.count
    )
  end

  # Credential helpers
  def verified_credentials
    credentials.select { |c| c["verified"] }
  end

  def pending_credentials
    credentials.reject { |c| c["verified"] }
  end

  def has_credential?(name)
    credentials.any? { |c| c["name"].to_s.downcase.include?(name.downcase) }
  end

  # Differentiator helpers
  def same_day_response?
    differentiators.include?("same_day_response")
  end

  def available_weekends?
    differentiators.include?("available_weekends")
  end

  def same_day_reports?
    differentiators.include?("same_day_reports")
  end

  def free_consultation?
    differentiators.include?("free_consultation")
  end

  # Service area helpers
  def serves_area?(suburb_or_postcode)
    service_areas.any? do |area|
      area.downcase == suburb_or_postcode.to_s.downcase ||
        area.include?(suburb_or_postcode.to_s)
    end
  end

  # Pricing helpers
  def price_for_service(service_key)
    service_pricing = pricing[service_key.to_s]
    return nil unless service_pricing

    service_pricing["price_cents"].to_i / 100.0 if service_pricing["price_cents"]
  end

  def service_description(service_key)
    pricing.dig(service_key.to_s, "description")
  end

  # Availability helpers
  def available_weekdays?
    availability["weekdays"]
  end

  def available_after_hours?
    availability["after_hours"]
  end

  # Featured helpers
  def currently_featured?
    featured? && (featured_until.nil? || featured_until > Time.current)
  end

  def feature_until!(end_date)
    update!(featured: true, featured_until: end_date)
  end

  def remove_feature!
    update!(featured: false, featured_until: nil)
  end
end
