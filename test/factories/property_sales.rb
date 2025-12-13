FactoryBot.define do
  factory :property_sale do
    property_id { "MyString" }
    address { "MyString" }
    unit_number { "MyString" }
    street_number { "MyString" }
    street_name { "MyString" }
    suburb { "MyString" }
    postcode { "MyString" }
    state { "MyString" }
    latitude { "9.99" }
    longitude { "9.99" }
    property_type { "MyString" }
    sale_price_cents { "" }
    contract_date { "2025-12-13" }
    settlement_date { "2025-12-13" }
    land_area_sqm { "9.99" }
    building_area_sqm { "9.99" }
    bedrooms { 1 }
    bathrooms { 1 }
    parking { 1 }
    year_built { 1 }
    zoning { "MyString" }
    land_value_cents { "" }
    land_value_date { "2025-12-13" }
    strata_lot { false }
    data_source { "MyString" }
    source_id { "MyString" }
  end
end
