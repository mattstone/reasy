# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    # Enable PostgreSQL extensions for UUID and array support
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      ## Lockable
      t.integer  :failed_attempts, default: 0, null: false
      t.string   :unlock_token
      t.datetime :locked_at

      ## User profile fields
      t.string :name, null: false
      t.string :phone
      t.string :phone_country_code, default: "AU"

      ## Roles - PostgreSQL array for multiple roles
      t.string :roles, array: true, default: [], null: false

      ## KYC verification
      t.string :kyc_status, default: "pending", null: false
      t.datetime :kyc_verified_at
      t.string :kyc_verification_id

      ## Onboarding
      t.datetime :onboarding_completed_at

      ## Terms acceptance
      t.datetime :terms_accepted_at
      t.string :last_terms_version_accepted
      t.datetime :privacy_policy_accepted_at
      t.string :last_privacy_version_accepted

      ## User preferences
      t.string :preferred_language, default: "en"
      t.string :timezone, default: "Australia/Sydney"
      t.jsonb :notification_preferences, default: {}

      ## Subscription/Payment
      t.string :subscription_status, default: "trial"
      t.datetime :subscription_started_at
      t.datetime :subscription_ends_at
      t.datetime :trial_ends_at
      t.string :stripe_customer_id

      ## Soft delete
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token, unique: true
    add_index :users, :unlock_token, unique: true
    add_index :users, :roles, using: :gin
    add_index :users, :kyc_status
    add_index :users, :subscription_status
    add_index :users, :deleted_at
    add_index :users, :stripe_customer_id, unique: true, where: "stripe_customer_id IS NOT NULL"
  end
end
