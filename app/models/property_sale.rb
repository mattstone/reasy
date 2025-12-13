# frozen_string_literal: true

class PropertySale < ApplicationRecord
  AUSTRALIAN_STATES = %w[NSW VIC QLD WA SA TAS ACT NT].freeze
  PROPERTY_TYPES = %w[house townhouse unit apartment land rural commercial other].freeze

  # Validations
  validates :source_id, presence: true, uniqueness: true
  validates :state, inclusion: { in: AUSTRALIAN_STATES }, allow_nil: true
  validates :property_type, inclusion: { in: PROPERTY_TYPES }, allow_nil: true

  # Scopes
  scope :in_state, ->(state) { where(state: state) }
  scope :in_suburb, ->(suburb) { where(suburb: suburb) }
  scope :in_postcode, ->(postcode) { where(postcode: postcode) }
  scope :by_type, ->(type) { where(property_type: type) }
  scope :houses, -> { where(property_type: %w[house townhouse]) }
  scope :units, -> { where(property_type: %w[unit apartment]) }
  scope :land, -> { where(property_type: "land") }

  scope :sold_between, ->(start_date, end_date) {
    where(contract_date: start_date..end_date)
  }

  scope :sold_in_year, ->(year) {
    sold_between(Date.new(year, 1, 1), Date.new(year, 12, 31))
  }

  scope :with_price, -> { where.not(sale_price_cents: nil) }

  # Simple distance calculation (Haversine)
  scope :near, ->(lat, lng, radius_km) {
    where(
      "(6371 * acos(cos(radians(?)) * cos(radians(latitude)) * cos(radians(longitude) - radians(?)) + sin(radians(?)) * sin(radians(latitude)))) <= ?",
      lat, lng, lat, radius_km
    )
  }

  # Class methods for aggregation
  class << self
    def median_price
      prices = with_price.pluck(:sale_price_cents).sort
      return nil if prices.empty?

      mid = prices.length / 2
      prices.length.odd? ? prices[mid] : (prices[mid - 1] + prices[mid]) / 2
    end

    def average_price
      with_price.average(:sale_price_cents)&.to_i
    end

    def price_percentile(percentile)
      prices = with_price.pluck(:sale_price_cents).sort
      return nil if prices.empty?

      index = (percentile / 100.0 * prices.length).ceil - 1
      prices[[index, 0].max]
    end
  end

  # Instance methods
  def sale_price
    return nil unless sale_price_cents
    sale_price_cents / 100.0
  end

  def land_value
    return nil unless land_value_cents
    land_value_cents / 100.0
  end

  def price_per_sqm
    return nil unless sale_price_cents && land_area_sqm&.positive?
    (sale_price_cents / 100.0) / land_area_sqm
  end

  def full_address
    parts = []
    parts << "#{unit_number}/" if unit_number.present?
    parts << street_number if street_number.present?
    parts << street_name if street_name.present?
    parts << suburb if suburb.present?
    parts << state if state.present?
    parts << postcode if postcode.present?
    parts.join(" ").presence || address
  end
end
