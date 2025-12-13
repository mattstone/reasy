# frozen_string_literal: true

class SuburbProfile < ApplicationRecord
  AUSTRALIAN_STATES = %w[NSW VIC QLD WA SA TAS ACT NT].freeze

  # Validations
  validates :suburb, presence: true
  validates :state, presence: true, inclusion: { in: AUSTRALIAN_STATES }
  validates :suburb, uniqueness: { scope: :state }

  # Scopes
  scope :in_state, ->(state) { where(state: state) }
  scope :in_postcode, ->(postcode) { where(postcode: postcode) }
  scope :with_pricing, -> { where.not(median_house_price_cents: nil) }

  # Simple distance calculation (Haversine)
  scope :near, ->(lat, lng, radius_km) {
    where(
      "(6371 * acos(cos(radians(?)) * cos(radians(latitude)) * cos(radians(longitude) - radians(?)) + sin(radians(?)) * sin(radians(latitude)))) <= ?",
      lat, lng, lat, radius_km
    )
  }

  # Associations
  has_many :property_sales, ->(suburb_profile) {
    where(suburb: suburb_profile.suburb, state: suburb_profile.state)
  }, class_name: "PropertySale", foreign_key: false

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

  def full_name
    "#{suburb}, #{state} #{postcode}"
  end

  # Calculate metrics from sales data
  def calculate_metrics_from_sales!(years: 1)
    start_date = years.years.ago.to_date
    end_date = Date.current

    house_sales = PropertySale.in_suburb(suburb).in_state(state).houses.sold_between(start_date, end_date)
    unit_sales = PropertySale.in_suburb(suburb).in_state(state).units.sold_between(start_date, end_date)

    self.median_house_price_cents = house_sales.median_price
    self.median_unit_price_cents = unit_sales.median_price
    self.sales_volume_12m = house_sales.count + unit_sales.count
    self.last_updated_at = Time.current
    save!
  end
end
