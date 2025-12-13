# frozen_string_literal: true

require "csv"

module DataImporters
  # Imports ABS Census data for postcode demographics
  # Data sourced from ABS TableBuilder or DataPacks (requires manual download)
  #
  # Expected CSV format:
  # postcode,population,median_age,median_household_income,avg_household_size,
  # owner_occupied_pct,rented_pct,mortgage_pct,unemployment_rate,
  # university_educated_pct,professional_occupation_pct,families_with_children_pct
  #
  # Download from: https://www.abs.gov.au/census/find-census-data/datapacks
  class AbsCensusImporter < BaseImporter
    CENSUS_YEAR = 2021

    def import!(file_path)
      log_progress "Starting ABS Census import from #{file_path} (mode: #{mode})"

      unless File.exist?(file_path)
        log_error "Census file not found: #{file_path}"
        return stats
      end

      CSV.foreach(file_path, headers: true) do |row|
        import_row(row)
      end

      report_stats
    end

    private

    def import_row(row)
      postcode = row["postcode"]&.strip

      return if postcode.blank?

      # Skip if not in MVP radius
      unless postcode_within_mvp_radius?(postcode)
        @stats[:skipped] += 1
        return
      end

      profile = PostcodeProfile.find_by(postcode: postcode)

      unless profile
        log_progress "Postcode #{postcode} not found, creating..."
        profile = PostcodeProfile.new(postcode: postcode, state: determine_state(postcode))
      end

      profile.assign_attributes(
        population: row["population"]&.to_i,
        median_age: row["median_age"]&.to_i,
        median_household_income_cents: parse_dollars(row["median_household_income"]),
        avg_household_size: row["avg_household_size"]&.to_f,
        owner_occupied_pct: row["owner_occupied_pct"]&.to_f,
        rented_pct: row["rented_pct"]&.to_f,
        mortgage_pct: row["mortgage_pct"]&.to_f,
        unemployment_rate: row["unemployment_rate"]&.to_f,
        university_educated_pct: row["university_educated_pct"]&.to_f,
        professional_occupation_pct: row["professional_occupation_pct"]&.to_f,
        families_with_children_pct: row["families_with_children_pct"]&.to_f,
        data_year: CENSUS_YEAR,
        data_source: "abs_census_#{CENSUS_YEAR}",
        last_updated_at: Time.current
      )

      if profile.save
        @stats[:imported] += 1
        log_progress "Imported census data for #{postcode}" if (@stats[:imported] % 50).zero?
      else
        log_error "Failed to save census data for #{postcode}: #{profile.errors.full_messages.join(', ')}"
      end
    rescue StandardError => e
      log_error "Error importing row: #{row.inspect}", e
    end

    def parse_dollars(value)
      return nil if value.blank?

      # Handle formats like "$1,234" or "1234" or "$1234.56"
      cleaned = value.to_s.gsub(/[$,]/, "")
      (cleaned.to_f * 100).to_i
    end

    def determine_state(postcode)
      # Australian postcode ranges by state
      pc = postcode.to_i
      case pc
      when 1000..2599, 2619..2899, 2921..2999
        "NSW"
      when 2600..2618, 2900..2920
        "ACT"
      when 3000..3999, 8000..8999
        "VIC"
      when 4000..4999, 9000..9999
        "QLD"
      when 5000..5999
        "SA"
      when 6000..6797, 6800..6999
        "WA"
      when 7000..7999
        "TAS"
      when 800..899
        "NT"
      else
        "NSW" # Default
      end
    end
  end
end
