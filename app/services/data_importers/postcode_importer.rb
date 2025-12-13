# frozen_string_literal: true

require "csv"
require "net/http"
require "uri"

module DataImporters
  # Imports Australian postcode data from free sources
  # Primary source: Australian Post Office data (publicly available)
  class PostcodeImporter < BaseImporter
    # Australian Government postcode data URL
    POSTCODE_DATA_URL = "https://raw.githubusercontent.com/matthewproctor/australianpostcodes/master/australian_postcodes.csv"

    def import!
      log_progress "Starting postcode import (mode: #{mode})"

      csv_data = fetch_csv_data
      return stats if csv_data.nil?

      CSV.parse(csv_data, headers: true) do |row|
        import_row(row)
      end

      report_stats
    end

    private

    def fetch_csv_data
      log_progress "Fetching postcode data from #{POSTCODE_DATA_URL}"

      uri = URI.parse(POSTCODE_DATA_URL)
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        response.body
      else
        log_error "Failed to fetch postcode data: #{response.code}"
        nil
      end
    rescue StandardError => e
      log_error "Error fetching postcode data", e
      nil
    end

    def import_row(row)
      postcode = row["postcode"]&.strip
      state = row["state"]&.strip&.upcase
      locality = row["locality"]&.strip&.titleize
      lat = row["lat"]&.to_f
      lng = row["long"]&.to_f

      return if postcode.blank? || state.blank?
      return unless PostcodeProfile::AUSTRALIAN_STATES.include?(state)

      # Skip if not in MVP radius (when in MVP mode)
      unless postcode_within_mvp_radius?(postcode) || within_mvp_radius?(lat, lng)
        @stats[:skipped] += 1
        return
      end

      profile = PostcodeProfile.find_or_initialize_by(postcode: postcode)

      # Only update if new or we have better data
      if profile.new_record? || profile.locality.blank?
        profile.assign_attributes(
          state: state,
          locality: locality,
          latitude: lat,
          longitude: lng,
          data_source: "australian_postcodes_github",
          last_updated_at: Time.current
        )

        if profile.save
          @stats[:imported] += 1
          log_progress "Imported postcode #{postcode} - #{locality}, #{state}" if (@stats[:imported] % 100).zero?
        else
          log_error "Failed to save postcode #{postcode}: #{profile.errors.full_messages.join(', ')}"
        end
      else
        @stats[:skipped] += 1
      end
    rescue StandardError => e
      log_error "Error importing row: #{row.inspect}", e
    end
  end
end
