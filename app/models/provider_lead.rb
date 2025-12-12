# frozen_string_literal: true

class ProviderLead < ApplicationRecord
  include Auditable

  # Status values
  STATUSES = %w[new contacted quoted accepted declined expired].freeze

  # Source values
  SOURCES = %w[platform referral ai_recommendation directory_search].freeze

  # Associations
  belongs_to :service_provider_profile
  belongs_to :property, optional: true
  belongs_to :user  # The buyer/seller who needs service
  has_one :provider_job, dependent: :nullify

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :source, inclusion: { in: SOURCES }, allow_blank: true
  validates :service_type, presence: true, inclusion: { in: ServiceProviderProfile::SERVICE_TYPES }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where(status: %w[new contacted quoted]) }
  scope :new_leads, -> { where(status: "new") }
  scope :contacted, -> { where(status: "contacted") }
  scope :quoted, -> { where(status: "quoted") }
  scope :accepted, -> { where(status: "accepted") }
  scope :declined, -> { where(status: "declined") }
  scope :expired, -> { where(status: "expired") }
  scope :expiring_soon, -> { where("expires_at <= ?", 48.hours.from_now).where.not(status: %w[accepted declined expired]) }
  scope :by_service_type, ->(type) { where(service_type: type) }
  scope :high_priority, -> { where("priority >= ?", 5) }

  # Callbacks
  before_create :set_expiry_date

  # Status transitions
  def mark_contacted!
    update!(status: "contacted", contacted_at: Time.current)
  end

  def mark_quoted!
    update!(status: "quoted")
  end

  def accept!
    update!(status: "accepted")
  end

  def decline!
    update!(status: "declined")
  end

  def expire!
    update!(status: "expired")
  end

  # Status helpers
  def new_lead?
    status == "new"
  end

  def active?
    status.in?(%w[new contacted quoted])
  end

  def closed?
    status.in?(%w[accepted declined expired])
  end

  def expiring_soon?
    expires_at.present? && expires_at <= 48.hours.from_now && active?
  end

  def expired?
    status == "expired" || (expires_at.present? && expires_at < Time.current && active?)
  end

  # Display helpers
  def status_badge_class
    case status
    when "new"
      "badge-blue"
    when "contacted"
      "badge-orange"
    when "quoted"
      "badge-purple"
    when "accepted"
      "badge-green"
    when "declined", "expired"
      "badge-gray"
    else
      "badge-gray"
    end
  end

  def provider
    service_provider_profile
  end

  def client
    user
  end

  private

  def set_expiry_date
    self.expires_at ||= 7.days.from_now
  end
end
