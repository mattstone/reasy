# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    password { "password123" }
    password_confirmation { "password123" }
    roles { ["buyer"] }
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :buyer do
      roles { ["buyer"] }
    end

    trait :seller do
      roles { ["seller"] }
    end

    trait :buyer_seller do
      roles { ["buyer", "seller"] }
    end

    trait :service_provider do
      roles { ["service_provider"] }
    end

    trait :admin do
      roles { ["admin"] }
    end

    trait :with_phone do
      phone { Faker::PhoneNumber.phone_number }
      phone_country_code { "AU" }
    end

    trait :verified do
      kyc_status { "verified" }
      kyc_verified_at { Time.current }
    end

    trait :subscribed do
      subscription_status { "active" }
      subscription_started_at { 1.month.ago }
      subscription_ends_at { 11.months.from_now }
    end

    trait :trial do
      subscription_status { "trial" }
      trial_ends_at { 24.hours.from_now }
    end

    trait :trial_expired do
      subscription_status { "trial" }
      trial_ends_at { 1.hour.ago }
    end

    trait :onboarded do
      onboarding_completed_at { Time.current }
    end

    trait :with_terms_accepted do
      terms_accepted_at { Time.current }
      privacy_policy_accepted_at { Time.current }
    end
  end
end
