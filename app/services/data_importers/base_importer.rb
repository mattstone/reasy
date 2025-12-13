# frozen_string_literal: true

module DataImporters
  class BaseImporter
    # Castle Hill coordinates for MVP radius
    CASTLE_HILL_LAT = -33.7314
    CASTLE_HILL_LNG = 150.9936
    MVP_RADIUS_KM = 10

    attr_reader :mode, :logger, :stats

    def initialize(mode: :mvp, logger: Rails.logger)
      @mode = mode.to_sym
      @logger = logger
      @stats = { imported: 0, skipped: 0, errors: 0 }
    end

    def import!
      raise NotImplementedError, "Subclasses must implement #import!"
    end

    def complete?
      mode == :complete
    end

    def mvp?
      mode == :mvp
    end

    protected

    def within_mvp_radius?(lat, lng)
      return true if complete?
      return false if lat.blank? || lng.blank?

      distance_km(CASTLE_HILL_LAT, CASTLE_HILL_LNG, lat.to_f, lng.to_f) <= MVP_RADIUS_KM
    end

    def postcode_within_mvp_radius?(postcode)
      return true if complete?

      # MVP postcodes around Castle Hill (10km radius)
      # These are pre-calculated postcodes within 10km of Castle Hill
      mvp_postcodes.include?(postcode.to_s)
    end

    def mvp_postcodes
      @mvp_postcodes ||= %w[
        2153 2154 2155 2156 2157 2158 2159
        2145 2146 2147 2148
        2150 2151 2152
        2160 2161 2162 2163 2164
        2125 2126 2127 2128
        2118 2119 2120 2121 2122
        2113 2114 2115 2116 2117
        2110 2111 2112
        2765 2766 2767 2768 2769 2770
      ].freeze
    end

    def distance_km(lat1, lng1, lat2, lng2)
      # Haversine formula
      rad_per_deg = Math::PI / 180
      earth_radius_km = 6371

      dlat = (lat2 - lat1) * rad_per_deg
      dlng = (lng2 - lng1) * rad_per_deg

      a = Math.sin(dlat / 2)**2 +
          Math.cos(lat1 * rad_per_deg) * Math.cos(lat2 * rad_per_deg) *
          Math.sin(dlng / 2)**2

      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

      earth_radius_km * c
    end

    def log_progress(message)
      logger.info "[#{self.class.name}] #{message}"
    end

    def log_error(message, exception = nil)
      logger.error "[#{self.class.name}] ERROR: #{message}"
      logger.error exception.backtrace.first(5).join("\n") if exception
      @stats[:errors] += 1
    end

    def report_stats
      log_progress "Import complete: #{stats[:imported]} imported, #{stats[:skipped]} skipped, #{stats[:errors]} errors"
      stats
    end
  end
end
