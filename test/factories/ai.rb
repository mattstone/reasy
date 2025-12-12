# frozen_string_literal: true

FactoryBot.define do
  factory :ai_conversation do
    association :user

    assistant { "sage" }
    started_at { Time.current }
    message_count { 0 }
    total_tokens { 0 }

    trait :with_max do
      assistant { "max" }
    end

    trait :with_nina do
      assistant { "nina" }
    end

    trait :with_doc do
      assistant { "doc" }
    end

    trait :with_scout do
      assistant { "scout" }
    end

    trait :with_ally do
      assistant { "ally" }
    end

    trait :completed do
      ended_at { Time.current }
    end

    trait :rated do
      user_rating { 4 }
      user_feedback { "Very helpful!" }
    end

    trait :with_messages do
      after(:create) do |conversation|
        create(:ai_message, :system, ai_conversation: conversation)
        create(:ai_message, :user, ai_conversation: conversation)
        create(:ai_message, :assistant, ai_conversation: conversation)
        conversation.update!(message_count: 3, total_tokens: 500)
      end
    end
  end

  factory :ai_message do
    association :ai_conversation

    role { "user" }
    content { Faker::Lorem.sentence }

    trait :system do
      role { "system" }
      content { "You are Sage, a helpful journey guide for Reasy." }
    end

    trait :user do
      role { "user" }
      content { "What should I consider when making an offer?" }
    end

    trait :assistant do
      role { "assistant" }
      content { Faker::Lorem.paragraph(sentence_count: 3) }
      tokens_used { rand(100..500) }
      model_version { "claude-3-sonnet" }
      response_time_ms { rand(500..2000) }
    end
  end

  factory :ai_voice_setting do
    assistant { "sage" }
    name { "Sage" }
    role { "Journey Guide" }
    personality_description { "Calm, wise, and patient." }
    tone_level { 5 }
    warmth_level { 9 }
    detail_level { 7 }
    sample_greeting { "Hello! I'm Sage, here to guide you through your property journey." }
    restricted_topics { ["legal_advice", "financial_advice", "tax_advice"] }
  end
end
