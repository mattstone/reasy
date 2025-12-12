# frozen_string_literal: true

class Property < ApplicationRecord
  include SoftDeletable
  include Auditable

  LISTING_INTENTS = %w[open_to_offers want_to_sell just_exploring].freeze
  STATUSES = %w[draft pending_review active under_offer sold withdrawn archived].freeze
  PROPERTY_TYPES = %w[house townhouse apartment unit land rural acreage commercial].freeze

  AUSTRALIAN_STATES = %w[NSW VIC QLD WA SA TAS ACT NT].freeze

  # Associations
  belongs_to :user
  belongs_to :entity, optional: true

  has_many :property_loves, class_name: "PropertyLove", dependent: :destroy
  has_many :lovers, through: :property_loves, source: :user
  has_many :property_views, dependent: :destroy
  has_many :property_enquiries, dependent: :destroy
  has_many :property_documents, dependent: :destroy

  has_many :offers, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :conversations, dependent: :nullify

  # Active Storage
  has_many_attached :photos
  has_many_attached :floor_plans
  has_one_attached :hero_image

  # Validations
  validates :listing_intent, presence: true, inclusion: { in: LISTING_INTENTS }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :street_address, presence: true
  validates :suburb, presence: true
  validates :state, presence: true, inclusion: { in: AUSTRALIAN_STATES }
  validates :postcode, presence: true, format: { with: /\A\d{4}\z/, message: "must be 4 digits" }
  validates :property_type, presence: true, inclusion: { in: PROPERTY_TYPES }

  validates :bedrooms, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :bathrooms, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :parking_spaces, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :published, -> { where.not(published_at: nil) }
  scope :open_to_offers, -> { where(listing_intent: "open_to_offers") }
  scope :want_to_sell, -> { where(listing_intent: "want_to_sell") }
  scope :verified, -> { where(ownership_verified: true) }
  scope :in_state, ->(state) { where(state: state) }
  scope :in_suburb, ->(suburb) { where(suburb: suburb) }
  scope :by_type, ->(type) { where(property_type: type) }
  scope :with_bedrooms, ->(min, max = nil) {
    max.present? ? where(bedrooms: min..max) : where("bedrooms >= ?", min)
  }
  scope :price_range, ->(min, max) {
    where("price_cents >= ? AND price_cents <= ?", min, max)
  }
  scope :recent, -> { order(published_at: :desc) }

  # Aliases for view compatibility
  alias_method :seller, :user

  def address
    full_address
  end

  def floor_area_sqm
    building_size_sqm
  end

  def featured?
    # Properties can be featured - for now return false unless we add a column
    false
  end

  def views_count
    view_count || 0
  end

  def enquiries_count
    enquiry_count || 0
  end

  def loves_count
    love_count || 0
  end

  # Address helpers
  def full_address
    [unit_number.present? ? "#{unit_number}/" : nil, street_address, suburb, state, postcode].compact.join(" ")
  end

  def short_address
    "#{street_address}, #{suburb}"
  end

  def location
    "#{suburb}, #{state} #{postcode}"
  end

  # Pricing helpers
  def price
    return nil unless price_cents

    price_cents / 100.0
  end

  def price=(value)
    self.price_cents = value.present? ? (value.to_f * 100).to_i : nil
  end

  def price_range_display
    return price_display if price_display.present?
    return "Price Hidden" if price_hidden?
    return format_price(price_cents) if price_cents.present?

    if price_min_cents.present? && price_max_cents.present?
      "#{format_price(price_min_cents)} - #{format_price(price_max_cents)}"
    elsif price_min_cents.present?
      "From #{format_price(price_min_cents)}"
    elsif price_max_cents.present?
      "Up to #{format_price(price_max_cents)}"
    else
      "Contact Owner"
    end
  end

  # Status helpers
  def draft?
    status == "draft"
  end

  def active?
    status == "active"
  end

  def under_offer?
    status == "under_offer"
  end

  def sold?
    status == "sold"
  end

  def can_receive_offers?
    active? && !price_hidden?
  end

  # Publishing
  def publish!
    return false unless draft? || status == "pending_review"

    update!(
      status: "active",
      published_at: Time.current
    )
  end

  def withdraw!
    return false unless active? || under_offer?

    update!(
      status: "withdrawn",
      withdrawn_at: Time.current
    )
  end

  def mark_under_offer!
    return false unless active?

    update!(
      status: "under_offer",
      under_offer_at: Time.current
    )
  end

  def mark_sold!(sale_price_cents: nil)
    update!(
      status: "sold",
      sold_at: Time.current,
      price_cents: sale_price_cents || price_cents
    )
  end

  # Engagement tracking
  def record_view!(user: nil, ip_address: nil, user_agent: nil, referrer: nil)
    property_views.create!(
      user: user,
      ip_address: ip_address,
      user_agent: user_agent,
      referrer: referrer,
      viewed_at: Time.current
    )
    # counter_cache on PropertyView handles incrementing view_count
  end

  def loved_by?(user)
    property_loves.exists?(user: user)
  end

  def toggle_love!(user)
    love = property_loves.find_by(user: user)
    if love
      love.destroy
      # counter_cache on PropertyLove handles decrementing love_count
      false
    else
      property_loves.create!(user: user)
      # counter_cache on PropertyLove handles incrementing love_count
      true
    end
  end

  private

  def format_price(cents)
    return nil unless cents

    price_value = cents / 100
    if price_value >= 1_000_000
      "$#{(price_value / 1_000_000.0).round(2)}M"
    elsif price_value >= 1_000
      "$#{(price_value / 1_000.0).round}K"
    else
      "$#{price_value}"
    end
  end
end
