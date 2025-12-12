# frozen_string_literal: true

class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      # Owner
      t.references :user, null: false, foreign_key: true, index: true
      t.references :entity, foreign_key: true, index: true

      # Listing intent: open_to_offers, want_to_sell, just_exploring
      t.string :listing_intent, null: false, default: "want_to_sell"

      # Status: draft, pending_review, active, under_offer, sold, withdrawn, archived
      t.string :status, null: false, default: "draft"

      # Address
      t.string :street_address, null: false
      t.string :unit_number
      t.string :suburb, null: false
      t.string :state, null: false
      t.string :postcode, null: false
      t.string :country, default: "Australia"

      # Coordinates for map
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8

      # Property details
      t.string :property_type, null: false  # house, townhouse, apartment, land, rural
      t.integer :bedrooms
      t.integer :bathrooms
      t.integer :parking_spaces
      t.integer :land_size_sqm
      t.integer :building_size_sqm
      t.integer :year_built

      # Pricing
      t.integer :price_cents
      t.integer :price_min_cents
      t.integer :price_max_cents
      t.string :price_display  # e.g., "Contact Agent", "Offers Over $800k"
      t.boolean :price_hidden, default: false

      # Content
      t.string :headline
      t.text :description
      t.text :ai_generated_description

      # Features
      t.string :features, array: true, default: []

      # Dates
      t.datetime :published_at
      t.datetime :under_offer_at
      t.datetime :sold_at
      t.datetime :withdrawn_at

      # Engagement metrics
      t.integer :view_count, default: 0
      t.integer :enquiry_count, default: 0
      t.integer :love_count, default: 0
      t.integer :offer_count, default: 0

      # Verification
      t.boolean :ownership_verified, default: false
      t.datetime :ownership_verified_at
      t.string :ownership_verification_method

      # Valuation
      t.integer :estimated_value_cents
      t.datetime :estimated_value_at
      t.string :valuation_source

      # Soft delete
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :properties, :listing_intent
    add_index :properties, :status
    add_index :properties, :suburb
    add_index :properties, :state
    add_index :properties, :postcode
    add_index :properties, :property_type
    add_index :properties, :bedrooms
    add_index :properties, :price_cents
    add_index :properties, [:latitude, :longitude]
    add_index :properties, :published_at
    add_index :properties, :features, using: :gin
    add_index :properties, :deleted_at

    # Property loves (like Instagram)
    create_table :property_loves do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :property, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :property_loves, [:user_id, :property_id], unique: true

    # Property views for analytics
    create_table :property_views do |t|
      t.references :property, null: false, foreign_key: true, index: true
      t.references :user, foreign_key: true, index: true

      t.string :ip_address
      t.text :user_agent
      t.string :referrer

      t.datetime :viewed_at, null: false
    end

    add_index :property_views, :viewed_at

    # Property enquiries
    create_table :property_enquiries do |t|
      t.references :property, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.references :entity, foreign_key: true

      t.text :message, null: false
      t.string :status, default: "pending"  # pending, responded, archived

      t.datetime :responded_at
      t.text :response

      t.timestamps
    end

    add_index :property_enquiries, :status

    # Property documents (contracts, reports, etc.)
    create_table :property_documents do |t|
      t.references :property, null: false, foreign_key: true, index: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }

      t.string :document_type, null: false  # contract, building_report, pest_report, strata_report, etc.
      t.string :title, null: false
      t.text :description

      t.boolean :visible_to_buyers, default: true
      t.boolean :requires_nda, default: false

      t.datetime :deleted_at

      t.timestamps
    end

    add_index :property_documents, :document_type
    add_index :property_documents, :visible_to_buyers
    add_index :property_documents, :deleted_at
  end
end
