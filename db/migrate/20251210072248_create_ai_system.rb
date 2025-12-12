# frozen_string_literal: true

class CreateAiSystem < ActiveRecord::Migration[8.1]
  def change
    # AI Voice Settings - configurable personality for each assistant
    create_table :ai_voice_settings do |t|
      # Which assistant: max, sage, nina, doc, scout, ally
      t.string :assistant, null: false

      # Display info
      t.string :name, null: false
      t.string :role, null: false

      # Personality configuration
      t.text :personality_description, null: false

      # Tone controls (1-10 scale)
      t.integer :tone_level, default: 5, null: false       # 1=casual, 10=formal
      t.integer :warmth_level, default: 7, null: false     # 1=cold, 10=warm
      t.integer :detail_level, default: 5, null: false     # 1=brief, 10=detailed

      # Sample responses for testing
      t.text :sample_greeting

      # Topics the AI should redirect to professionals
      t.string :restricted_topics, array: true, default: []

      # Who last modified
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :ai_voice_settings, :assistant, unique: true

    # AI Conversations
    create_table :ai_conversations do |t|
      t.references :user, null: false, foreign_key: true, index: true

      # Which assistant
      t.string :assistant, null: false

      # Context for the conversation
      t.string :context_type  # e.g., "Property", "Offer", "Journey"
      t.bigint :context_id

      # Timing
      t.datetime :started_at, null: false
      t.datetime :ended_at

      # Statistics
      t.integer :message_count, default: 0, null: false
      t.integer :total_tokens, default: 0, null: false

      # Additional context
      t.jsonb :metadata, default: {}

      # User feedback
      t.integer :user_rating # 1-5 stars
      t.text :user_feedback

      t.timestamps
    end

    add_index :ai_conversations, :assistant
    add_index :ai_conversations, [:context_type, :context_id]
    add_index :ai_conversations, :started_at
    add_index :ai_conversations, :user_rating

    # AI Messages
    create_table :ai_messages do |t|
      t.references :ai_conversation, null: false, foreign_key: true, index: true

      # Role: system, user, assistant
      t.string :role, null: false

      # Message content
      t.text :content, null: false

      # Token usage
      t.integer :tokens_used

      # Model info
      t.string :model_version

      # Response timing
      t.integer :response_time_ms

      # Full prompt context for assistant messages (for audit)
      t.jsonb :prompt_context, default: {}

      t.datetime :created_at, null: false
    end

    add_index :ai_messages, :role
    add_index :ai_messages, :created_at
  end
end
