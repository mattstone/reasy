# frozen_string_literal: true

module GoogleMaps
  class << self
    def api_key
      Rails.application.credentials.dig(:google_maps, :api_key)
    end
  end
end
