# frozen_string_literal: true

class PostcodeProfile < ApplicationRecord
  AUSTRALIAN_STATES = %w[NSW VIC QLD WA SA TAS ACT NT].freeze

  # Validations
  validates :postcode, presence: true, uniqueness: true, format: { with: /\A\d{4}\z/ }
  validates :state, presence: true, inclusion: { in: AUSTRALIAN_STATES }

  # Scopes
  scope :in_state, ->(state) { where(state: state) }
  scope :with_population, -> { where.not(population: nil) }
  scope :with_pricing, -> { where.not(median_house_price_cents: nil) }

  # Geocoding scope - find postcodes within radius of a point
  scope :within_radius, ->(lat, lng, radius_km) {
    where(
      "ST_DWithin(
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
        ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
        ?
      )",
      lng, lat, radius_km * 1000
    )
  }

  # Simple distance calculation (for non-PostGIS databases)
  scope :near, ->(lat, lng, radius_km) {
    # Haversine approximation using SQL
    where(
      "(6371 * acos(cos(radians(?)) * cos(radians(latitude)) * cos(radians(longitude) - radians(?)) + sin(radians(?)) * sin(radians(latitude)))) <= ?",
      lat, lng, lat, radius_km
    )
  }

  # Helper methods
  def median_house_price
    return nil unless median_house_price_cents
    median_house_price_cents / 100.0
  end

  def median_unit_price
    return nil unless median_unit_price_cents
    median_unit_price_cents / 100.0
  end

  def median_land_value
    return nil unless median_land_value_cents
    median_land_value_cents / 100.0
  end

  def median_household_income
    return nil unless median_household_income_cents
    median_household_income_cents / 100.0
  end

  def socioeconomic_tier
    return nil unless seifa_advantage_disadvantage

    case seifa_advantage_disadvantage
    when 0..800 then :low
    when 801..950 then :below_average
    when 951..1050 then :average
    when 1051..1150 then :above_average
    else :high
    end
  end
end
