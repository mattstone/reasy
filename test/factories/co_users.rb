# frozen_string_literal: true

FactoryBot.define do
  factory :co_user_invitation do
    association :inviter, factory: :user

    sequence(:email) { |n| "invited#{n}@example.com" }
    name { Faker::Name.name }
    relationship { "partner" }
    invitation_token { SecureRandom.urlsafe_base64(32) }
    invitation_sent_at { Time.current }
    invitation_expires_at { 7.days.from_now }
    status { "pending" }

    trait :accepted do
      association :invitee, factory: :user
      status { "accepted" }
      invitation_accepted_at { Time.current }
    end

    trait :declined do
      status { "declined" }
    end

    trait :expired do
      status { "expired" }
      invitation_expires_at { 1.day.ago }
    end

    trait :revoked do
      status { "revoked" }
    end
  end

  factory :co_user_relationship do
    association :primary_user, factory: :user
    association :co_user, factory: :user

    relationship { "partner" }
    status { "active" }

    can_view_listings { true }
    can_view_offers { true }
    can_send_messages { true }
    can_schedule_viewings { false }
    can_make_offers { false }

    trait :full_permissions do
      can_view_listings { true }
      can_view_offers { true }
      can_send_messages { true }
      can_schedule_viewings { true }
      can_make_offers { true }
    end

    trait :view_only do
      can_view_listings { true }
      can_view_offers { true }
      can_send_messages { false }
      can_schedule_viewings { false }
      can_make_offers { false }
    end

    trait :suspended do
      status { "suspended" }
    end

    trait :revoked do
      status { "revoked" }
    end
  end
end
