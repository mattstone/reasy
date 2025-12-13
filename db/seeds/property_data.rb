# frozen_string_literal: true

# Property Data Seeds
# This file creates sample property data for development/testing
# For real data, use the rake tasks with downloaded CSV files

puts "Seeding property data for MVP (Castle Hill area)..."

# Sample SEIFA scores for Castle Hill area (based on real 2021 data)
seifa_data = {
  "2153" => { irsad: 1060, ier: 1055, ieo: 1070 }, # Baulkham Hills
  "2154" => { irsad: 1080, ier: 1075, ieo: 1090 }, # Castle Hill
  "2155" => { irsad: 1100, ier: 1095, ieo: 1110 }, # Kellyville
  "2156" => { irsad: 1070, ier: 1065, ieo: 1080 }, # Annangrove
  "2157" => { irsad: 1050, ier: 1045, ieo: 1060 }, # Forest Glen
  "2158" => { irsad: 1090, ier: 1085, ieo: 1100 }, # Dural
  "2126" => { irsad: 1095, ier: 1090, ieo: 1105 }, # Cherrybrook
  "2125" => { irsad: 1085, ier: 1080, ieo: 1095 }, # West Pennant Hills
  "2119" => { irsad: 1075, ier: 1070, ieo: 1085 }, # Beecroft
  "2118" => { irsad: 1065, ier: 1060, ieo: 1075 }, # Carlingford
  "2121" => { irsad: 1055, ier: 1050, ieo: 1065 }, # Epping
  "2147" => { irsad: 980, ier: 975, ieo: 990 },    # Kings Langley
  "2768" => { irsad: 1020, ier: 1015, ieo: 1030 }, # Glenwood
  "2769" => { irsad: 1040, ier: 1035, ieo: 1050 }  # The Ponds
}

# Update postcodes with SEIFA data
seifa_data.each do |postcode, scores|
  profile = PostcodeProfile.find_by(postcode: postcode)
  next unless profile

  profile.update!(
    seifa_advantage_disadvantage: scores[:irsad],
    seifa_economic_resources: scores[:ier],
    seifa_education_occupation: scores[:ieo],
    data_year: 2021
  )
end
puts "  Updated #{seifa_data.count} postcodes with SEIFA data"

# Sample census demographics (simplified)
census_data = {
  "2153" => { population: 35_000, median_age: 38, median_income: 110_000, owner_pct: 45, rented_pct: 30 },
  "2154" => { population: 42_000, median_age: 40, median_income: 135_000, owner_pct: 50, rented_pct: 25 },
  "2155" => { population: 28_000, median_age: 36, median_income: 145_000, owner_pct: 55, rented_pct: 20 },
  "2156" => { population: 8_000, median_age: 42, median_income: 125_000, owner_pct: 60, rented_pct: 15 },
  "2158" => { population: 12_000, median_age: 44, median_income: 140_000, owner_pct: 65, rented_pct: 12 },
  "2126" => { population: 20_000, median_age: 41, median_income: 150_000, owner_pct: 55, rented_pct: 18 },
  "2125" => { population: 15_000, median_age: 43, median_income: 155_000, owner_pct: 58, rented_pct: 16 },
  "2119" => { population: 10_000, median_age: 40, median_income: 130_000, owner_pct: 52, rented_pct: 22 },
  "2118" => { population: 25_000, median_age: 37, median_income: 115_000, owner_pct: 40, rented_pct: 35 },
  "2121" => { population: 30_000, median_age: 35, median_income: 105_000, owner_pct: 38, rented_pct: 40 }
}

census_data.each do |postcode, data|
  profile = PostcodeProfile.find_by(postcode: postcode)
  next unless profile

  profile.update!(
    population: data[:population],
    median_age: data[:median_age],
    median_household_income_cents: data[:median_income] * 100,
    owner_occupied_pct: data[:owner_pct],
    rented_pct: data[:rented_pct],
    mortgage_pct: 100 - data[:owner_pct] - data[:rented_pct],
    data_source: "sample_census_2021",
    data_year: 2021
  )
end
puts "  Updated #{census_data.count} postcodes with census data"

# Sample property sales (representative of Castle Hill area)
sample_sales = [
  { suburb: "CASTLE HILL", postcode: "2154", property_type: "house", price: 2_100_000, date: "2024-06-15", beds: 4, baths: 2, land: 650 },
  { suburb: "CASTLE HILL", postcode: "2154", property_type: "house", price: 1_850_000, date: "2024-05-20", beds: 3, baths: 2, land: 550 },
  { suburb: "CASTLE HILL", postcode: "2154", property_type: "unit", price: 780_000, date: "2024-07-01", beds: 2, baths: 1, land: 0 },
  { suburb: "CASTLE HILL", postcode: "2154", property_type: "townhouse", price: 1_250_000, date: "2024-04-10", beds: 3, baths: 2, land: 200 },
  { suburb: "BAULKHAM HILLS", postcode: "2153", property_type: "house", price: 1_650_000, date: "2024-06-01", beds: 4, baths: 2, land: 580 },
  { suburb: "BAULKHAM HILLS", postcode: "2153", property_type: "house", price: 1_450_000, date: "2024-05-15", beds: 3, baths: 2, land: 500 },
  { suburb: "BAULKHAM HILLS", postcode: "2153", property_type: "unit", price: 650_000, date: "2024-07-10", beds: 2, baths: 1, land: 0 },
  { suburb: "CHERRYBROOK", postcode: "2126", property_type: "house", price: 2_350_000, date: "2024-05-25", beds: 5, baths: 3, land: 750 },
  { suburb: "CHERRYBROOK", postcode: "2126", property_type: "house", price: 1_950_000, date: "2024-06-20", beds: 4, baths: 2, land: 620 },
  { suburb: "WEST PENNANT HILLS", postcode: "2125", property_type: "house", price: 2_450_000, date: "2024-04-30", beds: 4, baths: 3, land: 800 },
  { suburb: "DURAL", postcode: "2158", property_type: "house", price: 2_800_000, date: "2024-05-10", beds: 5, baths: 3, land: 2000 },
  { suburb: "DURAL", postcode: "2158", property_type: "rural", price: 3_500_000, date: "2024-03-20", beds: 4, baths: 2, land: 10000 },
  { suburb: "CARLINGFORD", postcode: "2118", property_type: "house", price: 1_550_000, date: "2024-06-05", beds: 3, baths: 2, land: 480 },
  { suburb: "CARLINGFORD", postcode: "2118", property_type: "unit", price: 720_000, date: "2024-07-15", beds: 2, baths: 2, land: 0 },
  { suburb: "EPPING", postcode: "2121", property_type: "unit", price: 850_000, date: "2024-06-25", beds: 2, baths: 2, land: 0 },
  { suburb: "EPPING", postcode: "2121", property_type: "townhouse", price: 1_350_000, date: "2024-05-05", beds: 3, baths: 2, land: 180 },
  { suburb: "KINGS LANGLEY", postcode: "2147", property_type: "house", price: 1_150_000, date: "2024-06-10", beds: 4, baths: 2, land: 550 },
  { suburb: "GLENWOOD", postcode: "2768", property_type: "house", price: 1_280_000, date: "2024-05-30", beds: 4, baths: 2, land: 450 },
  { suburb: "THE PONDS", postcode: "2769", property_type: "house", price: 1_420_000, date: "2024-06-18", beds: 4, baths: 2, land: 400 },
  { suburb: "BEECROFT", postcode: "2119", property_type: "house", price: 2_200_000, date: "2024-04-22", beds: 4, baths: 2, land: 900 }
]

sample_sales.each_with_index do |sale, idx|
  PropertySale.create!(
    source_id: "sample_#{idx + 1}",
    suburb: sale[:suburb],
    postcode: sale[:postcode],
    state: "NSW",
    property_type: sale[:property_type],
    sale_price_cents: sale[:price] * 100,
    contract_date: Date.parse(sale[:date]),
    bedrooms: sale[:beds],
    bathrooms: sale[:baths],
    land_area_sqm: sale[:land],
    data_source: "sample_data"
  )
end
puts "  Created #{sample_sales.count} sample property sales"

# Update suburb profiles with calculated medians
SuburbProfile.where(state: "NSW").find_each do |profile|
  sales = PropertySale.in_suburb(profile.suburb).in_state("NSW")

  house_median = sales.houses.median_price
  unit_median = sales.units.median_price

  profile.update!(
    median_house_price_cents: house_median,
    median_unit_price_cents: unit_median,
    sales_volume_12m: sales.count,
    last_updated_at: Time.current
  )
end
puts "  Updated suburb profiles with median prices"

puts ""
puts "Property data seeding complete!"
puts "Run 'rake property_data:stats' to see summary"
