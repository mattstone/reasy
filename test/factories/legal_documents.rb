# frozen_string_literal: true

FactoryBot.define do
  factory :legal_document do
    sequence(:version) { |n| "1.#{n}" }
    document_type { "terms_and_conditions" }
    title { "Terms and Conditions" }
    content { Faker::Lorem.paragraphs(number: 10).join("\n\n") }
    requires_acceptance { true }
    is_draft { true }
    is_current { false }

    trait :terms do
      document_type { "terms_and_conditions" }
      title { "Terms and Conditions" }
    end

    trait :privacy do
      document_type { "privacy_policy" }
      title { "Privacy Policy" }
    end

    trait :published do
      is_draft { false }
      is_current { true }
      published_at { Time.current }
    end

    trait :draft do
      is_draft { true }
      is_current { false }
      published_at { nil }
    end
  end

  factory :legal_document_acceptance do
    association :user
    association :legal_document

    accepted_at { Time.current }
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }
  end
end
