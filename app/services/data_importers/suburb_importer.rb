# frozen_string_literal: true

require "csv"
require "net/http"
require "uri"

module DataImporters
  # Imports suburb data and coordinates
  # Uses postcode data to seed suburb profiles
  class SuburbImporter < BaseImporter
    def import!
      log_progress "Starting suburb import (mode: #{mode})"

      # Get all unique suburb/state/postcode combinations from postcodes
      PostcodeProfile.find_each do |postcode_profile|
        import_from_postcode(postcode_profile)
      end

      report_stats
    end

    private

    def import_from_postcode(postcode_profile)
      return if postcode_profile.locality.blank?

      suburb = postcode_profile.locality.upcase
      state = postcode_profile.state

      # Skip if not in MVP radius
      unless within_mvp_radius?(postcode_profile.latitude, postcode_profile.longitude)
        @stats[:skipped] += 1
        return
      end

      profile = SuburbProfile.find_or_initialize_by(suburb: suburb, state: state)

      if profile.new_record?
        profile.assign_attributes(
          postcode: postcode_profile.postcode,
          latitude: postcode_profile.latitude,
          longitude: postcode_profile.longitude,
          population: postcode_profile.population,
          median_age: postcode_profile.median_age,
          median_household_income_cents: postcode_profile.median_household_income_cents,
          avg_household_size: postcode_profile.avg_household_size,
          owner_occupied_pct: postcode_profile.owner_occupied_pct,
          rented_pct: postcode_profile.rented_pct,
          seifa_score: postcode_profile.seifa_advantage_disadvantage,
          data_year: postcode_profile.data_year,
          last_updated_at: Time.current
        )

        if profile.save
          @stats[:imported] += 1
          log_progress "Created suburb: #{suburb}, #{state}" if (@stats[:imported] % 20).zero?
        else
          log_error "Failed to save suburb #{suburb}: #{profile.errors.full_messages.join(', ')}"
        end
      else
        @stats[:skipped] += 1
      end
    rescue StandardError => e
      log_error "Error importing suburb from postcode #{postcode_profile.postcode}", e
    end
  end
end
