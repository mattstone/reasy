# frozen_string_literal: true

require "csv"

module DataImporters
  # Imports NSW Valuer General property sales data
  # Data is freely available from NSW Valuer General
  #
  # Download from: https://www.valuergeneral.nsw.gov.au/land_value_summaries/lv.php
  # Also: https://data.nsw.gov.au/ - search for "property sales"
  #
  # The CSV format varies by year, but typically includes:
  # district_code, property_id, unit_number, house_number, street_name,
  # locality, postcode, property_type, area, area_type, contract_date,
  # settlement_date, purchase_price, zoning, nature_of_property,
  # primary_purpose, strata_lot_number, comp_code, percent_interest,
  # dealing_number, legal_description
  class NswPropertySalesImporter < BaseImporter
    def import!(file_path)
      log_progress "Starting NSW property sales import from #{file_path} (mode: #{mode})"

      unless File.exist?(file_path)
        log_error "NSW sales file not found: #{file_path}"
        return stats
      end

      # Auto-detect delimiter (NSW data sometimes uses ; or ,)
      first_line = File.open(file_path, &:readline)
      delimiter = first_line.include?(";") ? ";" : ","

      CSV.foreach(file_path, headers: true, col_sep: delimiter, liberal_parsing: true) do |row|
        import_row(row)
      end

      report_stats
    end

    private

    def import_row(row)
      # Try various column name formats
      postcode = extract_field(row, %w[postcode post_code POSTCODE])
      suburb = extract_field(row, %w[locality suburb LOCALITY SUBURB])&.titleize

      return if postcode.blank? && suburb.blank?

      # Skip if not in MVP radius
      unless postcode_within_mvp_radius?(postcode)
        @stats[:skipped] += 1
        return
      end

      source_id = generate_source_id(row)
      return if source_id.blank?

      # Skip if already imported
      if PropertySale.exists?(source_id: source_id)
        @stats[:skipped] += 1
        return
      end

      sale = PropertySale.new(
        source_id: source_id,
        property_id: extract_field(row, %w[property_id property_number PROPERTY_ID]),
        address: build_address(row),
        unit_number: extract_field(row, %w[unit_number unit UNIT_NUMBER]),
        street_number: extract_field(row, %w[house_number street_number HOUSE_NUMBER]),
        street_name: extract_field(row, %w[street_name street STREET_NAME])&.titleize,
        suburb: suburb,
        postcode: postcode,
        state: "NSW",
        property_type: normalize_property_type(extract_field(row, %w[property_type zone_standard PROPERTY_TYPE nature_of_property])),
        sale_price_cents: parse_price(extract_field(row, %w[purchase_price sale_price PURCHASE_PRICE contract_price])),
        contract_date: parse_date(extract_field(row, %w[contract_date sale_date CONTRACT_DATE])),
        settlement_date: parse_date(extract_field(row, %w[settlement_date SETTLEMENT_DATE])),
        land_area_sqm: parse_area(row),
        zoning: extract_field(row, %w[zoning zone ZONING]),
        strata_lot: strata_lot?(row),
        data_source: "nsw_valuer_general"
      )

      if sale.save
        @stats[:imported] += 1
        log_progress "Imported #{@stats[:imported]} sales..." if (@stats[:imported] % 500).zero?
      else
        log_error "Failed to save sale: #{sale.errors.full_messages.join(', ')}"
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
      # Create a unique ID from available data
      dealing = extract_field(row, %w[dealing_number DEALING_NUMBER dealing])
      property_id = extract_field(row, %w[property_id PROPERTY_ID property_number])
      contract_date = extract_field(row, %w[contract_date CONTRACT_DATE sale_date])

      if dealing.present?
        "nsw_#{dealing}"
      elsif property_id.present? && contract_date.present?
        "nsw_#{property_id}_#{contract_date}"
      else
        nil
      end
    end

    def build_address(row)
      parts = []
      unit = extract_field(row, %w[unit_number unit UNIT_NUMBER])
      number = extract_field(row, %w[house_number street_number HOUSE_NUMBER])
      street = extract_field(row, %w[street_name street STREET_NAME])
      suburb = extract_field(row, %w[locality suburb LOCALITY SUBURB])

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
      when /house|dwelling|residence|cottage/
        "house"
      when /townhouse|town house|terrace/
        "townhouse"
      when /unit|flat|apartment|villa/
        "unit"
      when /land|vacant/
        "land"
      when /rural|farm|acreage/
        "rural"
      when /commercial|retail|office|industrial/
        "commercial"
      else
        "other"
      end
    end

    def parse_price(value)
      return nil if value.blank?

      cleaned = value.to_s.gsub(/[$,]/, "")
      price = cleaned.to_f

      # Skip obviously incorrect prices (typos, invalid data)
      return nil if price < 10_000 || price > 500_000_000

      (price * 100).to_i
    end

    def parse_date(value)
      return nil if value.blank?

      # Try various date formats
      Date.parse(value.to_s)
    rescue ArgumentError
      # Try DD/MM/YYYY format common in Australian data
      begin
        Date.strptime(value.to_s, "%d/%m/%Y")
      rescue ArgumentError
        nil
      end
    end

    def parse_area(row)
      area = extract_field(row, %w[area land_area AREA])
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

    def strata_lot?(row)
      strata = extract_field(row, %w[strata_lot_number strata_lot STRATA_LOT_NUMBER])
      strata.present?
    end
  end
end
