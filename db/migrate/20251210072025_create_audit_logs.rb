# frozen_string_literal: true

class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      # Who performed the action
      t.references :user, foreign_key: true, index: true

      # If an admin is impersonating a user
      t.bigint :impersonated_by_id

      # What action was performed
      t.string :action_type, null: false

      # What resource was affected
      t.string :resource_type, null: false
      t.bigint :resource_id, null: false

      # What changed (before/after for updates)
      t.jsonb :changes, default: {}

      # Additional context
      t.jsonb :metadata, default: {}

      # Request context for tracing
      t.string :ip_address
      t.text :user_agent
      t.string :session_id
      t.string :request_id

      t.datetime :created_at, null: false
    end

    add_index :audit_logs, :impersonated_by_id
    add_index :audit_logs, :action_type
    add_index :audit_logs, [:resource_type, :resource_id]
    add_index :audit_logs, :created_at
    add_index :audit_logs, :session_id
    add_index :audit_logs, :request_id

    add_foreign_key :audit_logs, :users, column: :impersonated_by_id
  end
end
