# Property Data System

A budget CoreLogic alternative providing Australian property values, land values, and demographic data.

## Overview

This system provides:
- **PostcodeProfile**: Demographics, SEIFA scores, and aggregate property data by postcode
- **SuburbProfile**: Suburb-level statistics including median prices and growth rates
- **PropertySale**: Individual property sale records from government data

## Data Sources (Free)

### 1. Australian Postcodes
- **Source**: [Matthew Proctor's Australian Postcodes](https://github.com/matthewproctor/australianpostcodes)
- **Auto-imported**: Yes, via `rake property_data:import_postcodes`
- **Data**: Postcode, locality, state, lat/lng coordinates

### 2. ABS Census Data
- **Source**: [ABS DataPacks](https://www.abs.gov.au/census/find-census-data/datapacks)
- **Manual download required**: Yes
- **Data**: Population, median age, income, household composition, education levels

### 3. SEIFA Indexes
- **Source**: [ABS SEIFA](https://www.abs.gov.au/statistics/people/people-and-communities/socio-economic-indexes-areas-seifa-australia)
- **Manual download required**: Yes
- **Data**: Socio-economic advantage/disadvantage scores by postcode

### 4. NSW Property Sales (Valuer General)
- **Source**: [NSW Valuer General](https://www.valuergeneral.nsw.gov.au/land_value_summaries/lv.php)
- **Alternative**: [data.nsw.gov.au](https://data.nsw.gov.au/) (search "property sales")
- **Manual download required**: Yes
- **Data**: Property sales including price, date, property type, area

### 5. NSW Land Values
- **Source**: [NSW Valuer General](https://www.valuergeneral.nsw.gov.au/land_value_summaries/lv.php)
- **Manual download required**: Yes
- **Data**: Land valuations by property

## Import Modes

### MVP Mode (Default)
Imports only data within 10km of Castle Hill (coordinates: -33.7314, 150.9936).
This covers suburbs like:
- Castle Hill, Baulkham Hills, Cherrybrook
- West Pennant Hills, Dural, Beecroft
- Carlingford, Epping, Parramatta
- Kings Langley, Glenwood, The Ponds

### Complete Mode
Imports all Australian data (larger database, longer import times).

## Quick Start

```bash
# 1. Import postcodes (automatic download)
rake "property_data:import_postcodes[mvp]"

# 2. Generate suburb profiles from postcodes
rake "property_data:import_suburbs[mvp]"

# 3. (Optional) Load sample data for development
rails runner "load 'db/seeds/property_data.rb'"

# 4. Check stats
rake property_data:stats
```

## Importing Real Data

### Census Data
1. Download from [ABS DataPacks](https://www.abs.gov.au/census/find-census-data/datapacks)
2. Select "Postal Areas (POA)" geography
3. Choose tables: G01 (population), G02 (income), G33 (tenure)
4. Create a CSV with columns:
   - postcode, population, median_age, median_household_income
   - avg_household_size, owner_occupied_pct, rented_pct, mortgage_pct
   - unemployment_rate, university_educated_pct, professional_occupation_pct
5. Run: `rake "property_data:import_census[/path/to/census.csv,mvp]"`

### SEIFA Data
1. Download from [ABS SEIFA](https://www.abs.gov.au/statistics/people/people-and-communities/socio-economic-indexes-areas-seifa-australia)
2. Get POA (Postal Areas) spreadsheet
3. Create CSV with columns: postcode, irsad, ier, ieo
4. Run: `rake "property_data:import_seifa[/path/to/seifa.csv,mvp]"`

### NSW Property Sales
1. Download from [NSW Valuer General](https://www.valuergeneral.nsw.gov.au/land_value_summaries/lv.php)
2. Select desired year(s) and regions
3. Run: `rake "property_data:import_nsw_sales[/path/to/sales.csv,mvp]"`

### NSW Land Values
1. Download from same source as property sales
2. Run: `rake "property_data:import_nsw_land_values[/path/to/landvalues.csv,mvp]"`

## Rake Tasks

| Task | Description |
|------|-------------|
| `property_data:import_postcodes[mode]` | Import postcode coordinates |
| `property_data:import_suburbs[mode]` | Generate suburb profiles |
| `property_data:import_census[file,mode]` | Import ABS census data |
| `property_data:import_seifa[file,mode]` | Import SEIFA indexes |
| `property_data:import_nsw_sales[file,mode]` | Import NSW property sales |
| `property_data:import_nsw_land_values[file,mode]` | Import NSW land values |
| `property_data:calculate_suburb_stats` | Recalculate suburb medians |
| `property_data:stats` | Show data summary |
| `property_data:import_mvp` | Run MVP import wizard |

## Usage in Code

```ruby
# Find postcodes near a location
PostcodeProfile.near(-33.73, 150.99, 5) # 5km radius

# Get suburb statistics
suburb = SuburbProfile.find_by(suburb: "CASTLE HILL", state: "NSW")
suburb.median_house_price  # => 2000000.0
suburb.seifa_score         # => 1080

# Query property sales
PropertySale.in_suburb("CASTLE HILL")
            .houses
            .sold_in_year(2024)
            .median_price  # => 195000000 (cents)

# Socioeconomic tier
postcode = PostcodeProfile.find_by(postcode: "2154")
postcode.socioeconomic_tier  # => :above_average
```

## Data Model

### PostcodeProfile
Primary key for demographic data.
- Demographics: population, median_age, household_income
- Housing: owner_occupied_pct, rented_pct, mortgage_pct
- SEIFA: advantage_disadvantage, economic_resources, education_occupation

### SuburbProfile
Suburb-level aggregation with calculated metrics.
- Prices: median_house_price, median_unit_price, median_land_value
- Growth: house_price_growth_1yr, house_price_growth_5yr
- Market: days_on_market, sales_volume_12m, rental_yield

### PropertySale
Individual sale records from government data.
- Address: street, suburb, postcode, state, lat/lng
- Sale: price, contract_date, settlement_date
- Property: type, bedrooms, bathrooms, land_area

## Notes

- All prices are stored in cents (multiply by 100 to store, divide to display)
- Coordinates use WGS84 (standard GPS coordinates)
- SEIFA scores range from ~700 (disadvantaged) to ~1200 (advantaged), mean ~1000
- Data is cached and can be refreshed by re-running imports
