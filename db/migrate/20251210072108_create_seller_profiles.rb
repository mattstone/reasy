# frozen_string_literal: true

class CreateSellerProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :seller_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      # Default entity for selling transactions
      t.references :default_entity, foreign_key: { to_table: :entities }

      # Preferred settlement period: asap (30 days), standard (42-45), flexible (90), specific
      t.string :preferred_settlement_period, default: "standard"
      t.date :specific_settlement_date

      # Buyer finance preferences - what types of buyers they'll accept
      t.boolean :accept_cash_buyers, default: true
      t.boolean :accept_pre_approved_buyers, default: true
      t.boolean :accept_finance_buyers, default: true

      # Communication preferences
      t.boolean :allow_direct_contact, default: true
      t.string :preferred_contact_method, default: "platform" # platform, email, phone

      # Viewing preferences
      t.boolean :allow_scheduled_viewings, default: true
      t.jsonb :viewing_availability, default: {} # e.g., { "weekdays": true, "weekends": true, "times": ["morning", "afternoon"] }

      # Soft delete
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :seller_profiles, :preferred_settlement_period
    add_index :seller_profiles, :deleted_at
  end
end
