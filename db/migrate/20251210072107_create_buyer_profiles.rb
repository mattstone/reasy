# frozen_string_literal: true

class CreateBuyerProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :buyer_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      # Default entity for buying transactions
      t.references :default_entity, foreign_key: { to_table: :entities }

      # Budget preferences
      t.integer :budget_min_cents
      t.integer :budget_max_cents
      t.string :budget_currency, default: "AUD"

      # Property type preferences (house, townhouse, apartment, land)
      t.string :property_types, array: true, default: []

      # Room requirements
      t.integer :bedrooms_min
      t.integer :bathrooms_min
      t.integer :parking_min

      # Search areas - stored as array of suburb/postcode strings
      t.string :search_areas, array: true, default: []

      # Location preferences stored as JSONB
      # e.g., { "near_primary_school": { "enabled": true, "max_km": 2 } }
      t.jsonb :location_preferences, default: {}

      # Must-have features (garage, garden, pool, etc.)
      t.string :must_have_features, array: true, default: []

      # Nice-to-have features
      t.string :nice_to_have_features, array: true, default: []

      # Finance status: cash, pre_approved, needs_finance, exploring
      t.string :finance_status, default: "exploring"

      # Pre-approval details (if applicable)
      t.string :pre_approval_lender
      t.integer :pre_approval_amount_cents
      t.date :pre_approval_expires_at

      # Buying timeline preferences
      t.string :buying_timeline # immediate, 3_months, 6_months, just_looking

      # First home buyer status (affects stamp duty etc.)
      t.boolean :first_home_buyer, default: false

      # Soft delete
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :buyer_profiles, :finance_status
    add_index :buyer_profiles, :search_areas, using: :gin
    add_index :buyer_profiles, :property_types, using: :gin
    add_index :buyer_profiles, :must_have_features, using: :gin
    add_index :buyer_profiles, :deleted_at
  end
end
