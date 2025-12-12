# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true, index: true

      # Notification type and content
      t.string :notification_type, null: false
      t.string :title, null: false
      t.text :body

      # Related resource (polymorphic)
      t.string :notifiable_type
      t.bigint :notifiable_id

      # Delivery channels
      t.boolean :send_email, default: true
      t.boolean :send_sms, default: false
      t.boolean :send_push, default: true

      # Delivery status
      t.datetime :email_sent_at
      t.datetime :sms_sent_at
      t.datetime :push_sent_at

      # Read status
      t.datetime :read_at

      # Action URL
      t.string :action_url
      t.string :action_text

      # Metadata
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :notifications, :notification_type
    add_index :notifications, [:notifiable_type, :notifiable_id]
    add_index :notifications, :read_at
    add_index :notifications, :created_at

    # Messages between users
    create_table :conversations do |t|
      t.references :property, foreign_key: true, index: true

      t.string :subject

      # Participants tracked via conversation_participants
      t.integer :message_count, default: 0

      t.datetime :last_message_at

      t.timestamps
    end

    create_table :conversation_participants do |t|
      t.references :conversation, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true

      t.datetime :last_read_at
      t.boolean :archived, default: false
      t.boolean :muted, default: false

      t.timestamps
    end

    add_index :conversation_participants, [:conversation_id, :user_id], unique: true, name: "idx_conv_participants_unique"

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true, index: true
      t.references :sender, null: false, foreign_key: { to_table: :users }, index: true

      t.text :content, null: false

      # Message type: text, system, ai_generated
      t.string :message_type, default: "text"

      t.datetime :edited_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :messages, :message_type
    add_index :messages, :created_at
    add_index :messages, :deleted_at

    # Saved searches for buyers
    create_table :saved_searches do |t|
      t.references :user, null: false, foreign_key: true, index: true

      t.string :name, null: false

      # Search criteria (JSON)
      t.jsonb :criteria, null: false, default: {}

      # Alert preferences
      t.boolean :email_alerts, default: true
      t.boolean :push_alerts, default: true
      t.string :alert_frequency, default: "instant"  # instant, daily, weekly

      t.datetime :last_alerted_at

      t.timestamps
    end

    add_index :saved_searches, :alert_frequency
  end
end
