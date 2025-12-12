# frozen_string_literal: true

FactoryBot.define do
  factory :review do
    reviewer { association :user }
    reviewee { association :user }

    reviewee_role { "seller" }
    overall_rating { 4 }
    body { Faker::Lorem.paragraph(sentence_count: 3) }

    trait :for_buyer do
      reviewee_role { "buyer" }
      category_ratings { { "communication" => 4, "reliability" => 5, "responsiveness" => 4 } }
    end

    trait :for_seller do
      reviewee_role { "seller" }
      category_ratings { { "communication" => 4, "honesty" => 5, "property_accuracy" => 4, "responsiveness" => 4 } }
    end

    trait :for_service_provider do
      reviewee_role { "service_provider" }
      category_ratings { { "communication" => 4, "professionalism" => 5, "quality" => 4, "timeliness" => 5, "value" => 4 } }
    end

    trait :positive do
      overall_rating { 5 }
      title { "Excellent experience!" }
    end

    trait :neutral do
      overall_rating { 3 }
      title { "It was okay" }
    end

    trait :negative do
      overall_rating { 2 }
      title { "Could have been better" }
      status { "held" }
      hold_until { 48.hours.from_now }
      hold_reason { "Automatic hold for negative review" }
    end

    trait :published do
      status { "published" }
    end

    trait :held do
      status { "held" }
      hold_until { 48.hours.from_now }
    end

    trait :with_response do
      public_response { Faker::Lorem.paragraph }
      public_response_at { Time.current }
    end
  end

  factory :review_dispute do
    association :review
    association :disputed_by, factory: :user

    reason { "false_information" }
    explanation { Faker::Lorem.paragraph(sentence_count: 3) }

    trait :pending do
      status { "pending" }
    end

    trait :under_review do
      status { "under_review" }
    end

    trait :upheld do
      status { "upheld" }
      association :resolved_by, factory: [:user, :admin]
      resolved_at { Time.current }
      resolution_notes { "Review contained false information" }
    end

    trait :rejected do
      status { "rejected" }
      association :resolved_by, factory: [:user, :admin]
      resolved_at { Time.current }
      resolution_notes { "No evidence of false information" }
    end
  end
end
