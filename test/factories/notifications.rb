# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    association :user
    notification_type { "system_announcement" }
    title { "Test Notification" }
    body { "This is a test notification body." }

    trait :offer_received do
      notification_type { "offer_received" }
      title { "New offer received" }
      body { "You've received an offer on your property." }
      association :notifiable, factory: :offer
    end

    trait :offer_accepted do
      notification_type { "offer_accepted" }
      title { "Your offer has been accepted!" }
      body { "Congratulations! The seller has accepted your offer." }
    end

    trait :message_received do
      notification_type { "message_received" }
      title { "New message" }
      body { "You have a new message." }
    end

    trait :read do
      read_at { Time.current }
    end

    trait :unread do
      read_at { nil }
    end

    trait :email_pending do
      send_email { true }
      email_sent_at { nil }
    end

    trait :email_sent do
      send_email { true }
      email_sent_at { Time.current }
    end

    trait :with_action do
      action_url { "/dashboard" }
      action_text { "View Details" }
    end
  end

  factory :conversation do
    association :property

    trait :without_property do
      property { nil }
    end

    transient do
      participants_count { 2 }
    end

    after(:create) do |conversation, evaluator|
      evaluator.participants_count.times do
        conversation.add_participant!(create(:user))
      end
    end
  end

  factory :conversation_participant do
    association :conversation
    association :user

    trait :archived do
      archived { true }
    end

    trait :muted do
      muted { true }
    end

    trait :with_unread do
      last_read_at { 1.hour.ago }
    end
  end

  factory :message do
    association :conversation
    association :sender, factory: :user
    content { Faker::Lorem.paragraph }
    message_type { "text" }

    trait :system do
      message_type { "system" }
      content { "System message content" }
    end

    trait :ai_generated do
      message_type { "ai_generated" }
      content { "AI generated response" }
    end

    trait :edited do
      edited_at { Time.current }
    end

    trait :deleted do
      deleted_at { Time.current }
    end
  end

  factory :saved_search do
    association :user
    name { "My Search" }
    criteria do
      {
        state: "NSW",
        suburbs: ["Sydney", "Bondi"],
        property_types: ["house", "apartment"],
        min_bedrooms: 2,
        max_price_cents: 1_500_000_00
      }
    end
    alert_frequency { "instant" }

    trait :daily do
      alert_frequency { "daily" }
    end

    trait :weekly do
      alert_frequency { "weekly" }
    end

    trait :no_alerts do
      email_alerts { false }
      push_alerts { false }
    end
  end
end
