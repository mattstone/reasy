# frozen_string_literal: true

FactoryBot.define do
  factory :offer do
    association :buyer, factory: :user
    property { association :property, :active, :with_pricing }
    amount_cents { 850_000_00 }
    finance_type { "pre_approved" }
    settlement_days { 42 }
    status { "draft" }

    trait :cash do
      finance_type { "cash" }
      subject_to_finance { false }
    end

    trait :pre_approved do
      finance_type { "pre_approved" }
      finance_lender { "Big Bank" }
    end

    trait :subject_to_finance do
      finance_type { "subject_to_finance" }
      subject_to_finance { true }
    end

    trait :with_conditions do
      subject_to_finance { true }
      subject_to_building_inspection { true }
      subject_to_pest_inspection { true }
    end

    trait :unconditional do
      subject_to_finance { false }
      subject_to_building_inspection { false }
      subject_to_pest_inspection { false }
      subject_to_valuation { false }
      subject_to_sale_of_property { false }
    end

    trait :cooling_off_waived do
      cooling_off_waived { true }
    end

    trait :submitted do
      status { "submitted" }
      submitted_at { 1.hour.ago }
      expires_at { 5.days.from_now }
    end

    trait :viewed do
      status { "viewed" }
      submitted_at { 2.hours.ago }
      viewed_at { 1.hour.ago }
    end

    trait :accepted do
      status { "accepted" }
      submitted_at { 3.days.ago }
      viewed_at { 3.days.ago }
      accepted_at { 2.days.ago }
      responded_at { 2.days.ago }
    end

    trait :rejected do
      status { "rejected" }
      submitted_at { 3.days.ago }
      rejected_at { 2.days.ago }
      responded_at { 2.days.ago }
      seller_response { "Thank you for your offer, but we've decided to go with another buyer." }
    end

    trait :withdrawn do
      status { "withdrawn" }
      submitted_at { 3.days.ago }
      withdrawn_at { 1.day.ago }
    end

    trait :expired do
      status { "expired" }
      submitted_at { 7.days.ago }
      expires_at { 2.days.ago }
    end

    trait :with_deposit do
      deposit_cents { 85_000_00 }
      deposit_percentage { 10 }
    end
  end

  factory :transaction do
    transient do
      skip_offer { false }
    end

    association :seller, factory: :user
    association :buyer, factory: :user
    # Property needs to be :active for offer validation, then will be :under_offer after accept
    property { association :property, :active, :with_pricing, user: seller }
    # Build offer and save without validation since it's already accepted (past the property check)
    after(:build) do |transaction, evaluator|
      next if evaluator.skip_offer

      if transaction.offer.nil? && transaction.property && transaction.buyer
        transaction.offer = Offer.new(
          property: transaction.property,
          buyer: transaction.buyer,
          amount_cents: 850_000_00,
          finance_type: "pre_approved",
          settlement_days: 42,
          status: "accepted",
          submitted_at: 3.days.ago,
          accepted_at: 2.days.ago,
          responded_at: 2.days.ago
        ).tap { |o| o.save(validate: false) }
      end
    end
    sale_price_cents { 850_000_00 }
    status { "pending" }

    trait :exchanged do
      status { "exchanged" }
      exchange_date { Date.current }
    end

    trait :cooling_off do
      status { "cooling_off" }
      exchange_date { Date.current }
      cooling_off_ends_at { 5.business_days.from_now }
    end

    trait :unconditional do
      status { "unconditional" }
      exchange_date { 10.days.ago.to_date }
      finance_approved { true }
      finance_approved_at { 7.days.ago }
    end

    trait :settling do
      status { "settling" }
      exchange_date { 30.days.ago.to_date }
      settlement_date { 12.days.from_now.to_date }
      finance_approved { true }
      building_inspection_passed { true }
      pest_inspection_passed { true }
    end

    trait :settled do
      status { "settled" }
      exchange_date { 60.days.ago.to_date }
      settlement_date { Date.current }
      settled_at { Time.current }
      finance_approved { true }
      building_inspection_passed { true }
      pest_inspection_passed { true }
    end

    trait :fallen_through do
      status { "fallen_through" }
      exchange_date { 30.days.ago.to_date }
      fallen_through_at { 5.days.ago }
      fallen_through_reason { "Finance not approved" }
    end

    trait :with_deposit do
      deposit_cents { 85_000_00 }
      deposit_paid_cents { 85_000_00 }
    end

    trait :with_conveyancers do
      association :buyer_conveyancer, factory: [:user, :service_provider]
      association :seller_conveyancer, factory: [:user, :service_provider]
    end
  end

  factory :transaction_event do
    association :property_transaction, factory: :transaction
    event_type { "custom" }
    title { "Event Title" }
    description { "Event description" }
    occurred_at { Time.current }

    trait :exchange do
      event_type { "exchanged" }
      title { "Contracts exchanged" }
    end

    trait :settlement do
      event_type { "settled" }
      title { "Property settled" }
    end

    trait :finance_approved do
      event_type { "finance_approved" }
      title { "Finance approved" }
    end
  end
end
