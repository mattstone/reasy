# frozen_string_literal: true

require "csv"

module DataImporters
  # Imports NSW Land Values data
  # Data is freely available from NSW Valuer General
  #
  # Download from: https://www.valuergeneral.nsw.gov.au/land_value_summaries/lv.php
  #
  # CSV format typically includes:
  # property_id, property_type, property_name, unit_number, house_number,
  # street_name, suburb, postcode, zone_code, zone_standard, area, area_type,
  # base_date, land_value, authority_code, authority_name
  class LandValueImporter < BaseImporter
    def import!(file_path)
      log_progress "Starting NSW land values import from #{file_path} (mode: #{mode})"

      unless File.exist?(file_path)
        log_error "Land values file not found: #{file_path}"
        return stats
      end

      CSV.foreach(file_path, headers: true, liberal_parsing: true) do |row|
        import_row(row)
      end

      update_suburb_medians
      report_stats
    end

    private

    def import_row(row)
      postcode = extract_field(row, %w[postcode POSTCODE])
      suburb = extract_field(row, %w[suburb locality SUBURB LOCALITY])&.upcase

      return if postcode.blank? && suburb.blank?

      # Skip if not in MVP radius
      unless postcode_within_mvp_radius?(postcode)
        @stats[:skipped] += 1
        return
      end

      source_id = generate_source_id(row)
      return if source_id.blank?

      # Update existing property sale or create a land value record
      land_value = parse_land_value(row)
      land_value_date = parse_date(extract_field(row, %w[base_date BASE_DATE valuation_date]))

      return if land_value.blank?

      # Try to find matching property sale
      property_id = extract_field(row, %w[property_id PROPERTY_ID])

      if property_id.present?
        sale = PropertySale.find_by(property_id: property_id, state: "NSW")
        if sale
          sale.update(
            land_value_cents: land_value,
            land_value_date: land_value_date
          )
          @stats[:imported] += 1
          return
        end
      end

      # Otherwise create a new record with land value
      sale = PropertySale.find_or_initialize_by(source_id: "nsw_lv_#{source_id}")

      sale.assign_attributes(
        property_id: property_id,
        address: build_address(row),
        unit_number: extract_field(row, %w[unit_number UNIT_NUMBER]),
        street_number: extract_field(row, %w[house_number HOUSE_NUMBER]),
        street_name: extract_field(row, %w[street_name STREET_NAME])&.titleize,
        suburb: suburb&.titleize,
        postcode: postcode,
        state: "NSW",
        property_type: normalize_property_type(extract_field(row, %w[property_type zone_standard PROPERTY_TYPE])),
        land_area_sqm: parse_area(row),
        zoning: extract_field(row, %w[zone_code zone_standard ZONE_CODE]),
        land_value_cents: land_value,
        land_value_date: land_value_date,
        data_source: "nsw_land_values"
      )

      if sale.save
        @stats[:imported] += 1
        log_progress "Imported #{@stats[:imported]} land values..." if (@stats[:imported] % 1000).zero?
      else
        log_error "Failed to save land value: #{sale.errors.full_messages.join(', ')}"
      end
    rescue StandardError => e
      log_error "Error importing row: #{row.inspect}", e
    end

    def extract_field(row, possible_keys)
      possible_keys.each do |key|
        value = row[key]
        return value.to_s.strip if value.present?
      end
      nil
    end

    def generate_source_id(row)
      property_id = extract_field(row, %w[property_id PROPERTY_ID])
      base_date = extract_field(row, %w[base_date BASE_DATE])

      if property_id.present?
        "#{property_id}_#{base_date}"
      else
        nil
      end
    end

    def build_address(row)
      parts = []
      unit = extract_field(row, %w[unit_number UNIT_NUMBER])
      number = extract_field(row, %w[house_number HOUSE_NUMBER])
      street = extract_field(row, %w[street_name STREET_NAME])
      suburb = extract_field(row, %w[suburb locality SUBURB LOCALITY])

      parts << "#{unit}/" if unit.present?
      parts << number if number.present?
      parts << street&.titleize if street.present?
      parts << suburb&.titleize if suburb.present?

      parts.join(" ").presence
    end

    def normalize_property_type(type)
      return nil if type.blank?

      type_lower = type.to_s.downcase

      case type_lower
      when /r1|r2|r3|r4|residential/
        "house"
      when /b1|b2|b3|b4|b5|b6|b7|b8|business|commercial/
        "commercial"
      when /in1|in2|in3|industrial/
        "commercial"
      when /ru1|ru2|ru3|ru4|ru5|ru6|rural/
        "rural"
      when /e1|e2|e3|e4|environmental/
        "land"
      else
        "other"
      end
    end

    def parse_land_value(row)
      value = extract_field(row, %w[land_value LAND_VALUE])
      return nil if value.blank?

      cleaned = value.to_s.gsub(/[$,]/, "")
      (cleaned.to_f * 100).to_i
    end

    def parse_date(value)
      return nil if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      begin
        Date.strptime(value.to_s, "%d/%m/%Y")
      rescue ArgumentError
        nil
      end
    end

    def parse_area(row)
      area = extract_field(row, %w[area AREA])
      area_type = extract_field(row, %w[area_type AREA_TYPE])&.downcase

      return nil if area.blank?

      area_value = area.to_f

      # Convert hectares to sqm if needed
      if area_type&.include?("h") || area_value < 100
        area_value * 10_000
      else
        area_value
      end
    end

    def update_suburb_medians
      log_progress "Updating suburb median land values..."

      # Group land values by suburb
      PropertySale.where.not(land_value_cents: nil)
                  .where(state: "NSW")
                  .group(:suburb)
                  .pluck(:suburb, Arel.sql("PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY land_value_cents)"))
                  .each do |suburb, median|
        profile = SuburbProfile.find_by(suburb: suburb&.upcase, state: "NSW")
        profile&.update(median_land_value_cents: median&.to_i)
      end
    rescue StandardError => e
      log_error "Error updating suburb medians", e
    end
  end
end
