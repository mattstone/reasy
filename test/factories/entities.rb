# frozen_string_literal: true

FactoryBot.define do
  factory :entity do
    association :user
    name { Faker::Name.name }
    entity_type { "individual" }
    is_default { true }

    trait :individual do
      entity_type { "individual" }
      date_of_birth { Faker::Date.birthday(min_age: 18, max_age: 65) }
    end

    trait :company do
      entity_type { "company" }
      company_name { Faker::Company.name }
      abn { Faker::Number.number(digits: 11).to_s }
      acn { Faker::Number.number(digits: 9).to_s }
      registered_address { Faker::Address.full_address }
      director_names { [Faker::Name.name, Faker::Name.name] }
    end

    trait :smsf do
      entity_type { "smsf" }
      fund_name { "#{Faker::Name.last_name} Family Super Fund" }
      fund_abn { Faker::Number.number(digits: 11).to_s }
      trustee_names { [Faker::Name.name, Faker::Name.name] }
    end

    trait :verified do
      verified_at { Time.current }
      verification_status { "verified" }
    end

    trait :not_default do
      is_default { false }
    end
  end
end
