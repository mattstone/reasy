FactoryBot.define do
  factory :postcode_profile do
    postcode { "MyString" }
    state { "MyString" }
    locality { "MyString" }
    latitude { "9.99" }
    longitude { "9.99" }
    population { 1 }
    median_age { 1 }
    median_household_income_cents { "" }
    median_house_price_cents { "" }
    median_unit_price_cents { "" }
    median_land_value_cents { "" }
    avg_household_size { "9.99" }
    owner_occupied_pct { "9.99" }
    rented_pct { "9.99" }
    mortgage_pct { "9.99" }
    unemployment_rate { "9.99" }
    university_educated_pct { "9.99" }
    professional_occupation_pct { "9.99" }
    families_with_children_pct { "9.99" }
    seifa_advantage_disadvantage { 1 }
    seifa_economic_resources { 1 }
    seifa_education_occupation { 1 }
    data_source { "MyString" }
    data_year { 1 }
    last_updated_at { "2025-12-13 15:06:54" }
  end
end
