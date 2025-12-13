# frozen_string_literal: true

require "csv"

module DataImporters
  # Imports SEIFA (Socio-Economic Indexes for Areas) data
  # Data sourced from ABS SEIFA release
  #
  # Expected CSV format:
  # postcode,irsad,irsd,ier,ieo
  # Where:
  # - IRSAD: Index of Relative Socio-economic Advantage and Disadvantage
  # - IRSD: Index of Relative Socio-economic Disadvantage
  # - IER: Index of Economic Resources
  # - IEO: Index of Education and Occupation
  #
  # Download from: https://www.abs.gov.au/statistics/people/people-and-communities/socio-economic-indexes-areas-seifa-australia
  class SeifaImporter < BaseImporter
    SEIFA_YEAR = 2021

    def import!(file_path)
      log_progress "Starting SEIFA import from #{file_path} (mode: #{mode})"

      unless File.exist?(file_path)
        log_error "SEIFA file not found: #{file_path}"
        return stats
      end

      CSV.foreach(file_path, headers: true) do |row|
        import_row(row)
      end

      report_stats
    end

    private

    def import_row(row)
      postcode = extract_postcode(row)
      return if postcode.blank?

      # Skip if not in MVP radius
      unless postcode_within_mvp_radius?(postcode)
        @stats[:skipped] += 1
        return
      end

      profile = PostcodeProfile.find_by(postcode: postcode)

      unless profile
        log_progress "Postcode #{postcode} not found for SEIFA data, skipping"
        @stats[:skipped] += 1
        return
      end

      profile.assign_attributes(
        seifa_advantage_disadvantage: extract_score(row, "irsad") || extract_score(row, "advantage_disadvantage"),
        seifa_economic_resources: extract_score(row, "ier") || extract_score(row, "economic_resources"),
        seifa_education_occupation: extract_score(row, "ieo") || extract_score(row, "education_occupation"),
        data_year: SEIFA_YEAR,
        last_updated_at: Time.current
      )

      if profile.save
        @stats[:imported] += 1
        log_progress "Imported SEIFA for #{postcode}" if (@stats[:imported] % 50).zero?
      else
        log_error "Failed to save SEIFA data for #{postcode}: #{profile.errors.full_messages.join(', ')}"
      end
    rescue StandardError => e
      log_error "Error importing row: #{row.inspect}", e
    end

    def extract_postcode(row)
      # Handle various column names
      row["postcode"]&.strip ||
        row["POA_CODE_2021"]&.gsub("POA", "")&.strip ||
        row["poa"]&.gsub("POA", "")&.strip
    end

    def extract_score(row, key)
      value = row[key] || row[key.upcase] || row[key.titleize]
      return nil if value.blank?

      value.to_i
    end
  end
end
