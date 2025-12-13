# frozen_string_literal: true

namespace :property_data do
  desc "Import Australian postcodes (mode: mvp or complete)"
  task :import_postcodes, [:mode] => :environment do |_t, args|
    mode = args[:mode]&.to_sym || :mvp
    puts "Importing postcodes (mode: #{mode})..."

    importer = DataImporters::PostcodeImporter.new(mode: mode)
    stats = importer.import!

    puts "Done! Imported: #{stats[:imported]}, Skipped: #{stats[:skipped]}, Errors: #{stats[:errors]}"
  end

  desc "Import ABS Census data from CSV (mode: mvp or complete)"
  task :import_census, [:file_path, :mode] => :environment do |_t, args|
    unless args[:file_path]
      puts "Usage: rake property_data:import_census[/path/to/census.csv,mvp]"
      puts ""
      puts "Download census data from: https://www.abs.gov.au/census/find-census-data/datapacks"
      puts ""
      puts "Expected CSV columns:"
      puts "  postcode, population, median_age, median_household_income,"
      puts "  avg_household_size, owner_occupied_pct, rented_pct, mortgage_pct,"
      puts "  unemployment_rate, university_educated_pct, professional_occupation_pct,"
      puts "  families_with_children_pct"
      exit 1
    end

    mode = args[:mode]&.to_sym || :mvp
    puts "Importing ABS Census data (mode: #{mode})..."

    importer = DataImporters::AbsCensusImporter.new(mode: mode)
    stats = importer.import!(args[:file_path])

    puts "Done! Imported: #{stats[:imported]}, Skipped: #{stats[:skipped]}, Errors: #{stats[:errors]}"
  end

  desc "Import SEIFA data from CSV (mode: mvp or complete)"
  task :import_seifa, [:file_path, :mode] => :environment do |_t, args|
    unless args[:file_path]
      puts "Usage: rake property_data:import_seifa[/path/to/seifa.csv,mvp]"
      puts ""
      puts "Download SEIFA data from: https://www.abs.gov.au/statistics/people/people-and-communities/socio-economic-indexes-areas-seifa-australia"
      puts ""
      puts "Expected CSV columns:"
      puts "  postcode (or POA_CODE_2021), irsad, ier, ieo"
      exit 1
    end

    mode = args[:mode]&.to_sym || :mvp
    puts "Importing SEIFA data (mode: #{mode})..."

    importer = DataImporters::SeifaImporter.new(mode: mode)
    stats = importer.import!(args[:file_path])

    puts "Done! Imported: #{stats[:imported]}, Skipped: #{stats[:skipped]}, Errors: #{stats[:errors]}"
  end

  desc "Import NSW property sales from Valuer General CSV (mode: mvp or complete)"
  task :import_nsw_sales, [:file_path, :mode] => :environment do |_t, args|
    unless args[:file_path]
      puts "Usage: rake property_data:import_nsw_sales[/path/to/sales.csv,mvp]"
      puts ""
      puts "Download NSW property sales data from:"
      puts "  https://www.valuergeneral.nsw.gov.au/land_value_summaries/lv.php"
      puts "  https://data.nsw.gov.au/ (search for 'property sales')"
      exit 1
    end

    mode = args[:mode]&.to_sym || :mvp
    puts "Importing NSW property sales (mode: #{mode})..."

    importer = DataImporters::NswPropertySalesImporter.new(mode: mode)
    stats = importer.import!(args[:file_path])

    puts "Done! Imported: #{stats[:imported]}, Skipped: #{stats[:skipped]}, Errors: #{stats[:errors]}"
  end

  desc "Import NSW land values from Valuer General CSV (mode: mvp or complete)"
  task :import_nsw_land_values, [:file_path, :mode] => :environment do |_t, args|
    unless args[:file_path]
      puts "Usage: rake property_data:import_nsw_land_values[/path/to/landvalues.csv,mvp]"
      puts ""
      puts "Download NSW land values from:"
      puts "  https://www.valuergeneral.nsw.gov.au/land_value_summaries/lv.php"
      exit 1
    end

    mode = args[:mode]&.to_sym || :mvp
    puts "Importing NSW land values (mode: #{mode})..."

    importer = DataImporters::LandValueImporter.new(mode: mode)
    stats = importer.import!(args[:file_path])

    puts "Done! Imported: #{stats[:imported]}, Skipped: #{stats[:skipped]}, Errors: #{stats[:errors]}"
  end

  desc "Import all data for MVP (Castle Hill 10km radius)"
  task import_mvp: :environment do
    puts "=" * 60
    puts "IMPORTING MVP DATA (10km radius around Castle Hill)"
    puts "=" * 60
    puts ""

    # Step 1: Postcodes
    puts "Step 1/3: Importing postcodes..."
    Rake::Task["property_data:import_postcodes"].invoke("mvp")
    puts ""

    # Step 2 & 3: Census and SEIFA require manual download
    puts "Step 2/3: Census data import"
    puts "  -> Download from: https://www.abs.gov.au/census/find-census-data/datapacks"
    puts "  -> Run: rake property_data:import_census[/path/to/file.csv,mvp]"
    puts ""

    puts "Step 3/3: NSW Sales data"
    puts "  -> Download from: https://www.valuergeneral.nsw.gov.au/land_value_summaries/lv.php"
    puts "  -> Run: rake property_data:import_nsw_sales[/path/to/file.csv,mvp]"
    puts ""

    puts "=" * 60
    puts "Postcode import complete!"
    puts "To complete MVP setup, download and import the CSV files above."
    puts "=" * 60
  end

  desc "Calculate suburb statistics from sales data"
  task calculate_suburb_stats: :environment do
    puts "Calculating suburb statistics..."

    SuburbProfile.find_each do |profile|
      profile.calculate_metrics_from_sales!
      print "."
    end

    puts ""
    puts "Done!"
  end

  desc "Generate suburb profiles from property sales"
  task generate_suburb_profiles: :environment do
    puts "Generating suburb profiles from property sales..."

    PropertySale.where.not(suburb: nil)
                .select(:suburb, :state, :postcode)
                .distinct
                .find_each do |sale|
      next if sale.suburb.blank? || sale.state.blank?

      profile = SuburbProfile.find_or_initialize_by(
        suburb: sale.suburb.upcase,
        state: sale.state
      )

      if profile.new_record?
        profile.postcode = sale.postcode
        profile.save!
        print "+"
      else
        print "."
      end
    end

    puts ""
    puts "Done! Now run: rake property_data:calculate_suburb_stats"
  end

  desc "Generate suburb profiles from postcode data"
  task :import_suburbs, [:mode] => :environment do |_t, args|
    mode = args[:mode]&.to_sym || :mvp
    puts "Generating suburb profiles from postcodes (mode: #{mode})..."

    importer = DataImporters::SuburbImporter.new(mode: mode)
    stats = importer.import!

    puts "Done! Imported: #{stats[:imported]}, Skipped: #{stats[:skipped]}, Errors: #{stats[:errors]}"
  end

  desc "Show data summary"
  task stats: :environment do
    puts "=" * 60
    puts "PROPERTY DATA SUMMARY"
    puts "=" * 60
    puts ""
    puts "Postcodes:       #{PostcodeProfile.count}"
    puts "  - With census: #{PostcodeProfile.where.not(population: nil).count}"
    puts "  - With SEIFA:  #{PostcodeProfile.where.not(seifa_advantage_disadvantage: nil).count}"
    puts ""
    puts "Property Sales:  #{PropertySale.count}"
    puts "  - Houses:      #{PropertySale.houses.count}"
    puts "  - Units:       #{PropertySale.units.count}"
    puts "  - Land:        #{PropertySale.land.count}"
    puts ""
    puts "Suburb Profiles: #{SuburbProfile.count}"
    puts "  - With prices: #{SuburbProfile.with_pricing.count}"
    puts ""

    if PropertySale.any?
      puts "Sales date range:"
      puts "  Earliest: #{PropertySale.minimum(:contract_date)}"
      puts "  Latest:   #{PropertySale.maximum(:contract_date)}"
      puts ""
      puts "Postcodes covered: #{PropertySale.distinct.count(:postcode)}"
      puts "Suburbs covered:   #{PropertySale.distinct.count(:suburb)}"
    end
  end
end
