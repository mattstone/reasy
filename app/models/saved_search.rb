# frozen_string_literal: true

class SavedSearch < ApplicationRecord
  ALERT_FREQUENCIES = %w[instant daily weekly].freeze

  belongs_to :user

  validates :name, presence: true
  validates :criteria, presence: true
  validates :alert_frequency, inclusion: { in: ALERT_FREQUENCIES }

  scope :with_email_alerts, -> { where(email_alerts: true) }
  scope :with_push_alerts, -> { where(push_alerts: true) }
  scope :instant_alerts, -> { where(alert_frequency: "instant") }
  scope :daily_alerts, -> { where(alert_frequency: "daily") }
  scope :weekly_alerts, -> { where(alert_frequency: "weekly") }
  scope :due_for_alert, ->(frequency) {
    case frequency
    when "daily"
      where("last_alerted_at IS NULL OR last_alerted_at < ?", 1.day.ago)
    when "weekly"
      where("last_alerted_at IS NULL OR last_alerted_at < ?", 1.week.ago)
    else
      all
    end
  }

  def instant?
    alert_frequency == "instant"
  end

  def daily?
    alert_frequency == "daily"
  end

  def weekly?
    alert_frequency == "weekly"
  end

  # Run the search and return matching properties
  def matching_properties
    scope = Property.active.published

    # Apply search criteria
    scope = apply_location_criteria(scope)
    scope = apply_property_criteria(scope)
    scope = apply_price_criteria(scope)
    scope = apply_feature_criteria(scope)

    scope
  end

  def new_matching_properties
    matching_properties.where("published_at > ?", last_alerted_at || created_at)
  end

  def alert!
    return unless should_alert?

    properties = new_matching_properties.limit(10)
    return if properties.empty?

    # TODO: Send alert notification/email
    update!(last_alerted_at: Time.current)

    properties
  end

  private

  def should_alert?
    return true if instant?
    return last_alerted_at.nil? || last_alerted_at < 1.day.ago if daily?
    return last_alerted_at.nil? || last_alerted_at < 1.week.ago if weekly?

    false
  end

  def apply_location_criteria(scope)
    scope = scope.where(state: criteria["state"]) if criteria["state"].present?
    scope = scope.where(suburb: criteria["suburbs"]) if criteria["suburbs"].present?
    scope = scope.where(postcode: criteria["postcodes"]) if criteria["postcodes"].present?
    scope
  end

  def apply_property_criteria(scope)
    scope = scope.where(property_type: criteria["property_types"]) if criteria["property_types"].present?
    scope = scope.where("bedrooms >= ?", criteria["min_bedrooms"]) if criteria["min_bedrooms"].present?
    scope = scope.where("bedrooms <= ?", criteria["max_bedrooms"]) if criteria["max_bedrooms"].present?
    scope = scope.where("bathrooms >= ?", criteria["min_bathrooms"]) if criteria["min_bathrooms"].present?
    scope = scope.where("parking_spaces >= ?", criteria["min_parking"]) if criteria["min_parking"].present?
    scope
  end

  def apply_price_criteria(scope)
    scope = scope.where("price_cents >= ?", criteria["min_price_cents"]) if criteria["min_price_cents"].present?
    scope = scope.where("price_cents <= ?", criteria["max_price_cents"]) if criteria["max_price_cents"].present?
    scope
  end

  def apply_feature_criteria(scope)
    if criteria["features"].present?
      criteria["features"].each do |feature|
        scope = scope.where("? = ANY(features)", feature)
      end
    end
    scope
  end
end
