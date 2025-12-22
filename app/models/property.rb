# frozen_string_literal: true

class Property < ApplicationRecord
  include SoftDeletable
  include Auditable

  LISTING_INTENTS = %w[open_to_offers want_to_sell just_exploring].freeze
  STATUSES = %w[draft pending_review active under_offer sold withdrawn archived].freeze
  PROPERTY_TYPES = %w[house townhouse apartment unit land rural acreage commercial].freeze

  AUSTRALIAN_STATES = %w[NSW VIC QLD WA SA TAS ACT NT].freeze

  # Geocoding
  geocoded_by :full_address
  after_validation :geocode, if: :should_geocode?

  # Slug generation for SEO-friendly URLs
  before_validation :generate_slug, on: :create
  before_validation :regenerate_slug_if_address_changed, on: :update
  validates :slug, uniqueness: { scope: [:state, :suburb] }, allow_nil: true

  # Associations
  belongs_to :user
  belongs_to :entity, optional: true

  has_many :property_loves, class_name: "PropertyLove", dependent: :destroy
  has_many :lovers, through: :property_loves, source: :user
  has_many :property_analyses, dependent: :destroy
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
  scope :in_state, ->(state) { where("properties.state": state) }
  scope :in_suburb, ->(suburb) { where("properties.suburb": suburb) }
  scope :by_type, ->(type) { where(property_type: type) }
  scope :with_bedrooms, ->(min, max = nil) {
    max.present? ? where(bedrooms: min..max) : where("bedrooms >= ?", min)
  }
  scope :price_range, ->(min, max) {
    where("price_cents >= ? AND price_cents <= ?", min, max)
  }
  scope :recent, -> { order(published_at: :desc) }

  # Score-based scopes for Reasy Score functionality
  # Note: Uses inline COALESCE in ORDER BY to avoid conflicts with includes/select
  scope :by_reasy_score, ->(direction = :desc) {
    joins("LEFT JOIN suburb_profiles ON UPPER(properties.suburb) = suburb_profiles.suburb AND properties.state = suburb_profiles.state")
      .joins("LEFT JOIN postcode_profiles ON properties.postcode = postcode_profiles.postcode")
      .order(Arel.sql("COALESCE(suburb_profiles.property_score, postcode_profiles.property_score, 0) #{direction == :asc ? 'ASC' : 'DESC'}"))
  }

  scope :top_investment_areas, -> {
    by_reasy_score(:desc)
      .where("COALESCE(suburb_profiles.property_score, postcode_profiles.property_score, 0) >= 80")
  }

  scope :with_reasy_score_in_range, ->(min_score, max_score) {
    joins("LEFT JOIN suburb_profiles ON UPPER(properties.suburb) = suburb_profiles.suburb AND properties.state = suburb_profiles.state")
      .joins("LEFT JOIN postcode_profiles ON properties.postcode = postcode_profiles.postcode")
      .where("COALESCE(suburb_profiles.property_score, postcode_profiles.property_score) BETWEEN ? AND ?", min_score, max_score)
  }

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

  # Reasy Score accessors - delegate to PostcodeProfile/SuburbProfile
  def postcode_profile
    @postcode_profile ||= PostcodeProfile.find_by(postcode: postcode)
  end

  def suburb_profile
    @suburb_profile ||= SuburbProfile.find_by(suburb: suburb&.upcase, state: state)
  end

  def reasy_score
    # Calculate dynamically from weighted components
    calculated_reasy_score || suburb_profile&.property_score || postcode_profile&.property_score
  end

  # Calculate Reasy Score with user-specific weights
  # Returns the custom-weighted score if user has customized weights, otherwise default score
  def reasy_score_for_user(user)
    return reasy_score unless user&.buyer_profile&.using_custom_weights?

    calculate_score_with_weights(user.buyer_profile.normalized_score_weights)
  end

  # Calculate Reasy Score from weighted components
  # Growth (20%), Safety (15%), Transport (15%), Hazard (15%), Education (10%), Yield (10%), Tenants (10%), Economy (5%)
  def calculated_reasy_score
    components = []
    weights = []

    # Growth Potential (20%) - from growth_potential_normalized or land value growth
    if (growth = growth_potential_normalized)
      components << growth
      weights << 20
    elsif (land_growth = land_value_growth_5yr)
      # Normalize: 0% -> 30, 5% -> 50, 10% -> 70, 15%+ -> 85+
      normalized = land_growth > 0 ? [30 + (land_growth * 4), 100].min : 30
      components << normalized
      weights << 20
    end

    # Safety (15%)
    if (safety = crime_score)
      components << safety
      weights << 15
    end

    # Transport Accessibility (15%)
    if (transport = transport_score)
      components << transport
      weights << 15
    end

    # Natural Hazard Risk (15%) - inverted (100 = safest)
    if (hazard = hazard_score)
      components << hazard
      weights << 15
    end

    # Education (10%)
    if (edu = education_score)
      components << edu
      weights << 10
    end

    # Rental Yield (10%) - normalize to 0-100 (5% yield = 100 score)
    if (yield_pct = rental_yield)
      normalized_yield = [[yield_pct * 20, 0].max, 100].min
      components << normalized_yield
      weights << 10
    end

    # Tenant Quality (10%)
    if (tenant = tenant_quality_score)
      components << tenant
      weights << 10
    end

    # Socioeconomic (5%) - normalize SEIFA (500-1200) to 0-100
    if (seifa = socioeconomic_score)
      normalized_seifa = [[(seifa - 500) / 7.0, 0].max, 100].min
      components << normalized_seifa
      weights << 5
    end

    return nil if components.empty?

    # Calculate weighted average
    total_weight = weights.sum
    weighted_sum = components.zip(weights).sum { |score, weight| score * weight }
    (weighted_sum / total_weight).round(1)
  end

  def investor_score
    suburb_profile&.investor_score || postcode_profile&.investor_score
  end

  def crime_score
    suburb_profile&.crime_score || postcode_profile&.crime_score
  end

  def crime_band
    suburb_profile&.crime_band || postcode_profile&.crime_band
  end

  def crime_trend
    suburb_profile&.crime_trend || postcode_profile&.crime_trend
  end

  def tenant_quality_score
    suburb_profile&.tenant_quality_score || postcode_profile&.tenant_quality_score
  end

  def education_score
    suburb_profile&.calculated_education_score || postcode_profile&.calculated_education_score
  end

  def avg_school_icsea
    suburb_profile&.avg_school_icsea || postcode_profile&.avg_school_icsea
  end

  def school_count
    suburb_profile&.school_count || postcode_profile&.school_count
  end

  def land_value_growth_1yr
    suburb_profile&.land_value_growth_1yr || postcode_profile&.land_value_growth_1yr
  end

  def land_value_growth_5yr
    suburb_profile&.land_value_growth_5yr || postcode_profile&.land_value_growth_5yr
  end

  # Transport accessibility score (0-100, higher = better access)
  def transport_score
    suburb_profile&.transport_score || postcode_profile&.transport_score
  end

  def nearest_train_station
    suburb_profile&.nearest_train_station || postcode_profile&.nearest_train_station
  end

  def train_station_distance_km
    suburb_profile&.train_station_distance_km || postcode_profile&.train_station_distance_km
  end

  def train_station_count_5km
    suburb_profile&.train_station_count_5km || postcode_profile&.train_station_count_5km
  end

  def ferry_wharf_distance_km
    suburb_profile&.ferry_wharf_distance_km || postcode_profile&.ferry_wharf_distance_km
  end

  # Find nearby places of worship
  # Returns array of hashes with place info and distance
  def nearby_places_of_worship(radius_km: 2.0, limit: 10)
    return [] unless latitude.present? && longitude.present?

    PlaceOfWorship.near(latitude, longitude, radius_km: radius_km, limit: limit)
  end

  # Natural hazard risk score (0-100, higher = safer)
  def hazard_score
    suburb_profile&.hazard_score || postcode_profile&.hazard_score
  end

  def flood_risk
    suburb_profile&.flood_risk || postcode_profile&.flood_risk
  end

  def bushfire_risk
    suburb_profile&.bushfire_risk || postcode_profile&.bushfire_risk
  end

  def coastal_risk
    suburb_profile&.coastal_risk || postcode_profile&.coastal_risk
  end

  def reasy_score_band
    score = reasy_score
    return nil unless score

    case score
    when 80..100 then :excellent
    when 65..79 then :good
    when 50..64 then :average
    when 35..49 then :below_average
    else :low
    end
  end

  def top_investment_area?
    (reasy_score || 0) >= 80
  end

  def score_breakdown
    return nil unless suburb_profile || postcode_profile

    {
      overall: reasy_score,
      growth: growth_potential,
      growth_score: growth_potential_normalized,
      safety: crime_score,
      crime_band: crime_band,
      crime_trend: crime_trend,
      transport: transport_score,
      nearest_station: nearest_train_station,
      station_distance_km: train_station_distance_km,
      stations_nearby: train_station_count_5km,
      ferry_distance_km: ferry_wharf_distance_km,
      hazard: hazard_score,
      flood_risk: flood_risk,
      bushfire_risk: bushfire_risk,
      coastal_risk: coastal_risk,
      education: education_score,
      avg_icsea: avg_school_icsea,
      school_count: school_count,
      tenant_quality: tenant_quality_score,
      socioeconomic: socioeconomic_score,
      rental_yield: rental_yield,
      land_growth_1yr: land_value_growth_1yr,
      land_growth_5yr: land_value_growth_5yr
    }
  end

  # Growth potential - returns the growth percentage
  def growth_potential
    # Prefer land value growth as it's more accurate
    land_value_growth_5yr || suburb_profile&.house_price_growth_5yr || postcode_profile&.try(:house_price_growth_5yr)
  end

  # Growth potential normalized to 0-100 score
  def growth_potential_normalized
    suburb_profile&.growth_potential_score || postcode_profile&.growth_potential_score
  end

  def socioeconomic_score
    suburb_profile&.seifa_score || postcode_profile&.seifa_advantage_disadvantage
  end

  def rental_yield
    # Try pre-calculated yields first
    yield_value = suburb_profile&.rental_yield_house ||
                  suburb_profile&.rental_yield_unit ||
                  postcode_profile&.gross_rental_yield ||
                  postcode_profile&.try(:rental_yield_house)
    return yield_value if yield_value.present?

    # Calculate on-the-fly if we have rent and price data
    calculate_rental_yield
  end

  def calculate_rental_yield
    # Try to calculate from available rent and price data
    weekly_rent = estimated_weekly_rent_cents ||
                  postcode_profile&.median_weekly_rent_cents ||
                  suburb_profile&.median_weekly_rent_unit_cents ||
                  suburb_profile&.median_weekly_rent_house_cents
    return nil unless weekly_rent.present?

    # Get appropriate price based on property type
    price = if property_type.in?(%w[apartment unit])
              suburb_profile&.median_unit_price_cents || postcode_profile&.median_unit_price_cents
            else
              suburb_profile&.median_house_price_cents || postcode_profile&.median_house_price_cents
            end
    return nil unless price.present? && price > 0

    # Calculate yield: (annual rent / price) * 100
    annual_rent = weekly_rent * 52
    ((annual_rent.to_f / price) * 100).round(2)
  end

  # Get bedroom-specific rent estimate based on property type and bedrooms
  # Falls back from suburb_profile to postcode_profile if the value is nil
  def estimated_weekly_rent_cents
    is_unit = property_type.in?(%w[apartment unit townhouse])
    br = bedrooms.to_i

    # Try suburb profile first, then postcode profile
    [suburb_profile, postcode_profile].compact.each do |profile|
      rent = rent_for_profile(profile, is_unit, br)
      return rent if rent.present?
    end

    nil
  end

  # Calculate score with custom weights
  # weights should be a hash like { growth: 25, safety: 20, ... }
  def calculate_score_with_weights(weights)
    components = {
      growth: growth_potential_normalized || normalized_land_growth,
      safety: crime_score,
      transport: transport_score,
      hazards: hazard_score,
      education: education_score,
      yield: rental_yield_normalized,
      tenants: tenant_quality_score,
      economy: socioeconomic_normalized
    }

    # Only include components with values
    valid_components = components.compact
    return nil if valid_components.empty?

    # Get weights for available components only
    available_weights = weights.slice(*valid_components.keys)
    total_weight = available_weights.values.sum
    return nil if total_weight.zero?

    # Calculate weighted average
    weighted_sum = valid_components.sum do |key, score|
      weight = (available_weights[key] || 0) / total_weight.to_f
      score * weight
    end

    weighted_sum.round(1)
  end

  private

  # Normalized helpers for custom score calculation
  def normalized_land_growth
    return nil unless land_value_growth_5yr

    # Normalize: 0% -> 30, 5% -> 50, 10% -> 70, 15%+ -> 85+
    land_value_growth_5yr > 0 ? [30 + (land_value_growth_5yr * 4), 100].min : 30
  end

  def rental_yield_normalized
    return nil unless rental_yield

    # Normalize to 0-100 (5% yield = 100 score)
    [[rental_yield * 20, 0].max, 100].min
  end

  def socioeconomic_normalized
    return nil unless socioeconomic_score

    # Normalize SEIFA (500-1200) to 0-100
    [[(socioeconomic_score - 500) / 7.0, 0].max, 100].min
  end

  def rent_for_profile(profile, is_unit, br)
    return nil unless profile

    if is_unit
      case br
      when 0
        profile.median_rent_studio_unit_cents
      when 1
        profile.median_rent_1br_unit_cents
      when 2
        profile.median_rent_2br_unit_cents
      when 3
        profile.median_rent_3br_unit_cents
      else
        profile.median_rent_4br_plus_unit_cents
      end
    else
      case br
      when 0, 1
        profile.median_rent_1br_house_cents
      when 2
        profile.median_rent_2br_house_cents
      when 3
        profile.median_rent_3br_house_cents
      when 4
        profile.median_rent_4br_house_cents
      else
        profile.median_rent_5br_plus_house_cents
      end
    end
  end

  public

  # Get estimated weekly rent as dollars
  def estimated_weekly_rent
    cents = estimated_weekly_rent_cents
    return nil unless cents

    (cents / 100.0).round
  end

  # SEO-friendly URL components
  # URL format: /properties/au/:state/:suburb/:slug
  def seo_state
    state&.downcase
  end

  def seo_suburb
    suburb&.downcase&.gsub(/[^a-z0-9]/, "-")&.gsub(/-+/, "-")&.gsub(/^-|-$/, "")
  end

  def seo_slug
    slug.presence || id.to_s
  end

  # Generate SEO path parameters for URL helpers
  def to_seo_params
    { state: seo_state, suburb: seo_suburb, slug: seo_slug }
  end

  # For backward compatibility - returns just the slug
  def to_param
    slug.presence || id.to_s
  end

  # Find by SEO params or legacy ID
  def self.find_by_seo_params(state:, suburb:, slug:)
    # Normalize the slug lookup - try direct match first
    property = find_by(slug: slug)
    return property if property&.seo_state == state&.downcase && property&.seo_suburb == suburb

    # Fallback: search by state and suburb then match slug
    where("LOWER(state) = ?", state&.downcase)
      .where("LOWER(REGEXP_REPLACE(suburb, '[^a-zA-Z0-9]', '-', 'g')) = ?", suburb)
      .find_by(slug: slug)
  end

  # Find by slug or ID (for compatibility)
  def self.friendly_find(param)
    find_by(slug: param) || find(param)
  end

  private

  def generate_slug
    return if slug.present?

    base_slug = build_slug_base
    return if base_slug.blank?

    self.slug = ensure_unique_slug(base_slug)
  end

  def regenerate_slug_if_address_changed
    return unless street_address_changed? || suburb_changed? || state_changed?

    base_slug = build_slug_base
    return if base_slug.blank?

    self.slug = ensure_unique_slug(base_slug)
  end

  def build_slug_base
    return nil unless street_address.present?

    # Format: property-type-street-number-street-name (state and suburb are in URL path)
    parts = []
    parts << property_type if property_type.present?
    parts << street_address.gsub(%r{[/\\]}, "-")

    parts.join("-")
         .downcase
         .gsub(/[^a-z0-9\s-]/, "")
         .gsub(/\s+/, "-")
         .gsub(/-+/, "-")
         .gsub(/^-|-$/, "")
  end

  def ensure_unique_slug(base)
    candidate = base
    counter = 1

    # Ensure uniqueness within the same suburb/state (since those are in the URL path)
    scope = Property.where(suburb: suburb, state: state).where.not(id: id)

    while scope.exists?(slug: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end

    candidate
  end

  def should_geocode?
    return false unless street_address.present? && suburb.present? && state.present?
    return true if latitude.blank? || longitude.blank?

    # Re-geocode if address changed
    street_address_changed? || suburb_changed? || state_changed? || postcode_changed?
  end

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
