# frozen_string_literal: true

FactoryBot.define do
  factory :buyer_profile do
    association :user

    budget_min_cents { 500_000_00 }
    budget_max_cents { 800_000_00 }
    property_types { ["house", "townhouse"] }
    bedrooms_min { 3 }
    bathrooms_min { 2 }
    parking_min { 1 }
    search_areas { ["Sydney", "Newtown", "Marrickville"] }
    must_have_features { ["garage", "garden"] }
    finance_status { "exploring" }
    buying_timeline { "3_months" }

    trait :cash_buyer do
      finance_status { "cash" }
    end

    trait :pre_approved do
      finance_status { "pre_approved" }
      pre_approval_lender { "Commonwealth Bank" }
      pre_approval_amount_cents { 750_000_00 }
      pre_approval_expires_at { 3.months.from_now }
    end

    trait :first_home_buyer do
      first_home_buyer { true }
    end
  end

  factory :seller_profile do
    association :user

    preferred_settlement_period { "standard" }
    accept_cash_buyers { true }
    accept_pre_approved_buyers { true }
    accept_finance_buyers { true }
    allow_direct_contact { true }
    preferred_contact_method { "platform" }
    allow_scheduled_viewings { true }
    viewing_availability { { "weekdays" => true, "weekends" => true, "times" => ["morning", "afternoon"] } }

    trait :specific_date do
      preferred_settlement_period { "specific" }
      specific_settlement_date { 60.days.from_now }
    end

    trait :cash_only do
      accept_cash_buyers { true }
      accept_pre_approved_buyers { false }
      accept_finance_buyers { false }
    end
  end

  factory :service_provider_profile do
    association :user

    business_name { Faker::Company.name }
    service_type { "building_inspector" }
    headline { "Trusted building inspector with 15+ years experience" }
    description { Faker::Lorem.paragraph(sentence_count: 5) }
    service_areas { ["Sydney", "Inner West", "Eastern Suburbs"] }
    response_time_commitment { "24_hours" }
    accepting_new_clients { true }

    trait :verified do
      verification_status { "verified" }
      verified_at { Time.current }
    end

    trait :featured do
      featured { true }
      featured_until { 30.days.from_now }
    end

    trait :conveyancer do
      service_type { "conveyancer" }
    end

    trait :mortgage_broker do
      service_type { "mortgage_broker" }
    end
  end
end
