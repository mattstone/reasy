# Reasy

A modern Australian real estate platform built with Rails 8, featuring peer-to-peer property transactions, smart property matching, and comprehensive property data analytics.

## Features

- **Property Listings**: List and browse properties with rich media support
- **Smart Matching**: AI-powered property recommendations based on buyer preferences
- **Offer Management**: Submit, negotiate, and track offers through the complete lifecycle
- **Transaction Tracking**: End-to-end transaction management from offer to settlement
- **Service Provider Directory**: Connect with conveyancers, solicitors, and other professionals
- **Property Data Analytics**: Budget CoreLogic alternative with Australian property values and demographics

## Tech Stack

- **Framework**: Rails 8.1
- **Ruby**: 3.3.6
- **Database**: PostgreSQL
- **Background Jobs**: Solid Queue / Sidekiq
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Asset Pipeline**: Propshaft
- **Payments**: Stripe
- **File Storage**: Active Storage with S3
- **Geocoding**: Geocoder gem

## Getting Started

### Prerequisites

- Ruby 3.3.6
- PostgreSQL
- Node.js (for asset compilation)

### Setup

```bash
# Clone the repository
git clone <repository-url>
cd reasy

# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate

# Load sample data (optional)
bin/rails db:seed

# Start the server
bin/dev
```

### Environment Variables

Create a `.env` file with:

```bash
# Database
DATABASE_URL=postgresql://localhost/reasy_development

# Stripe (payments)
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_SECRET_KEY=sk_test_xxx

# AWS S3 (file uploads)
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx
AWS_BUCKET=xxx
AWS_REGION=ap-southeast-2

# Google Maps (optional, falls back to Nominatim)
GOOGLE_MAPS_API_KEY=xxx
```

## Property Data System

Reasy includes a comprehensive property data system - a budget alternative to CoreLogic providing Australian property values, land values, and demographic data.

### Data Models

| Model | Description |
|-------|-------------|
| `PostcodeProfile` | Demographics, SEIFA scores, aggregate data by postcode |
| `SuburbProfile` | Suburb-level statistics, median prices, growth rates |
| `PropertySale` | Individual property sale records from government data |

### Free Data Sources

| Source | Data Provided | Auto-Import |
|--------|---------------|-------------|
| [Australian Postcodes](https://github.com/matthewproctor/australianpostcodes) | Postcode coordinates | Yes |
| [ABS Census](https://www.abs.gov.au/census/find-census-data/datapacks) | Demographics, income, housing | Manual CSV |
| [ABS SEIFA](https://www.abs.gov.au/statistics/people/people-and-communities/socio-economic-indexes-areas-seifa-australia) | Socioeconomic indexes | Manual CSV |
| [NSW Valuer General](https://www.valuergeneral.nsw.gov.au/land_value_summaries/lv.php) | Property sales, land values | Manual CSV |

### Import Modes

- **MVP Mode**: Data within 10km of Castle Hill (for development/testing)
- **Complete Mode**: All Australian data

### Quick Start

```bash
# Import postcodes (auto-downloads)
bin/rails "property_data:import_postcodes[mvp]"

# Generate suburb profiles
bin/rails "property_data:import_suburbs[mvp]"

# Load sample data for development
bin/rails runner "load 'db/seeds/property_data.rb'"

# View statistics
bin/rails property_data:stats
```

### Sample Output

```
============================================================
PROPERTY DATA SUMMARY
============================================================

Postcodes:       66
  - With census: 10
  - With SEIFA:  14

Property Sales:  20
  - Houses:      15
  - Units:       4

Suburb Profiles: 26
  - With prices: 11
```

### Usage Examples

```ruby
# Find postcodes near a location
PostcodeProfile.near(-33.73, 150.99, 5) # 5km radius

# Get suburb statistics
suburb = SuburbProfile.find_by(suburb: "CASTLE HILL", state: "NSW")
suburb.median_house_price  # => 1850000.0
suburb.seifa_score         # => 1080

# Query property sales
PropertySale.in_suburb("CASTLE HILL")
            .houses
            .sold_in_year(2024)
            .median_price  # => 185000000 (cents)

# Socioeconomic tier
postcode = PostcodeProfile.find_by(postcode: "2154")
postcode.socioeconomic_tier  # => :above_average
```

### Available Rake Tasks

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

See [doc/property_data.md](doc/property_data.md) for complete documentation.

## Testing

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/property_test.rb

# Run system tests
bin/rails test:system
```

## Deployment

The application is configured for deployment with Kamal and Docker:

```bash
# Deploy to production
kamal deploy
```

## Project Structure

```
app/
├── controllers/
│   ├── buyer/          # Buyer-specific controllers
│   ├── seller/         # Seller-specific controllers
│   └── service_provider/
├── models/
│   ├── property.rb
│   ├── offer.rb
│   ├── transaction.rb
│   ├── postcode_profile.rb
│   ├── suburb_profile.rb
│   └── property_sale.rb
├── services/
│   └── data_importers/ # Property data import services
└── views/
    ├── buyer/
    ├── seller/
    └── shared/

doc/
└── property_data.md    # Property data system documentation

lib/
└── tasks/
    └── property_data.rake  # Data import tasks
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary software. All rights reserved.
