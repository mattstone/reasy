FactoryBot.define do
  factory :suburb_profile do
    suburb { "MyString" }
    postcode { "MyString" }
    state { "MyString" }
    latitude { "9.99" }
    longitude { "9.99" }
    population { 1 }
    median_age { 1 }
    median_household_income_cents { "" }
    median_house_price_cents { "" }
    median_unit_price_cents { "" }
    median_land_value_cents { "" }
    house_price_growth_1yr { "9.99" }
    house_price_growth_5yr { "9.99" }
    unit_price_growth_1yr { "9.99" }
    unit_price_growth_5yr { "9.99" }
    rental_yield_house { "9.99" }
    rental_yield_unit { "9.99" }
    days_on_market_house { 1 }
    days_on_market_unit { 1 }
    sales_volume_12m { 1 }
    avg_household_size { "9.99" }
    owner_occupied_pct { "9.99" }
    rented_pct { "9.99" }
    seifa_score { 1 }
    school_catchment_primary { "MyString" }
    school_catchment_secondary { "MyString" }
    data_year { 1 }
    last_updated_at { "2025-12-13 15:07:39" }
  end
end
