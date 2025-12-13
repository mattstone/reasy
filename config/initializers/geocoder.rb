# frozen_string_literal: true

Geocoder.configure(
  # Geocoding options
  timeout: 15,
  lookup: ENV["GOOGLE_MAPS_API_KEY"].present? ? :google : :nominatim,
  api_key: ENV["GOOGLE_MAPS_API_KEY"],
  use_https: true,

  # Nominatim specific (free, no API key needed)
  nominatim: {
    host: "nominatim.openstreetmap.org",
    use_https: true
  },

  # Calculation options
  units: :km,

  # Caching
  cache: Rails.cache,
  cache_options: {
    expiration: 1.day
  }
)
