# frozen_string_literal: true

FactoryBot.define do
  factory :property do
    association :user
    street_address { Faker::Address.street_address }
    suburb { Faker::Address.city }
    state { Property::AUSTRALIAN_STATES.sample }
    postcode { rand(2000..7999).to_s }
    property_type { "house" }
    listing_intent { "want_to_sell" }
    status { "draft" }

    trait :apartment do
      property_type { "apartment" }
      unit_number { rand(1..50).to_s }
    end

    trait :house do
      property_type { "house" }
      bedrooms { rand(3..5) }
      bathrooms { rand(1..3) }
      parking_spaces { rand(1..2) }
    end

    trait :land do
      property_type { "land" }
      land_size_sqm { rand(400..2000) }
    end

    trait :with_pricing do
      price_cents { rand(500_000..2_000_000) * 100 }
    end

    trait :with_price_range do
      price_min_cents { 800_000_00 }
      price_max_cents { 900_000_00 }
    end

    trait :active do
      status { "active" }
      published_at { 1.week.ago }
    end

    trait :under_offer do
      status { "under_offer" }
      published_at { 1.month.ago }
      under_offer_at { 1.day.ago }
    end

    trait :sold do
      status { "sold" }
      published_at { 2.months.ago }
      sold_at { 1.week.ago }
    end

    trait :withdrawn do
      status { "withdrawn" }
      withdrawn_at { 1.day.ago }
    end

    trait :open_to_offers do
      listing_intent { "open_to_offers" }
    end

    trait :just_exploring do
      listing_intent { "just_exploring" }
    end

    trait :verified do
      ownership_verified { true }
      ownership_verified_at { 1.week.ago }
      ownership_verification_method { "title_search" }
    end

    trait :with_full_details do
      bedrooms { 4 }
      bathrooms { 2 }
      parking_spaces { 2 }
      land_size_sqm { 650 }
      building_size_sqm { 220 }
      year_built { 2015 }
      headline { "Beautiful Family Home in Great Location" }
      description { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
      features { %w[pool aircon garage solar dishwasher] }
    end

    trait :with_coordinates do
      latitude { Faker::Address.latitude }
      longitude { Faker::Address.longitude }
    end
  end

  factory :property_love do
    association :user
    association :property
  end

  factory :property_view do
    association :property
    association :user
    viewed_at { Time.current }
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }

    trait :anonymous do
      user { nil }
    end
  end

  factory :property_enquiry do
    association :property
    association :user
    message { Faker::Lorem.paragraph }
    status { "pending" }

    trait :responded do
      status { "responded" }
      response { Faker::Lorem.paragraph }
      responded_at { Time.current }
    end

    trait :archived do
      status { "archived" }
    end
  end

  factory :property_document do
    association :property
    association :uploaded_by, factory: :user
    document_type { "contract" }
    title { "Contract of Sale" }
    description { "Standard contract of sale document" }

    trait :building_report do
      document_type { "building_report" }
      title { "Building Inspection Report" }
    end

    trait :pest_report do
      document_type { "pest_report" }
      title { "Pest Inspection Report" }
    end

    trait :strata_report do
      document_type { "strata_report" }
      title { "Strata Report" }
    end

    trait :requires_nda do
      requires_nda { true }
    end

    trait :hidden do
      visible_to_buyers { false }
    end
  end
end
