# frozen_string_literal: true

class CreateServiceProviderProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :service_provider_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      # Business information
      t.string :business_name, null: false
      t.string :abn
      t.text :business_address
      t.string :business_phone
      t.string :business_email

      # Service type: conveyancer, building_inspector, pest_inspector, mortgage_broker, etc.
      t.string :service_type, null: false

      # Profile content
      t.string :headline
      t.text :description
      t.string :profile_photo_url

      # Credentials and certifications (stored as JSONB array)
      # e.g., [{ "name": "Licensed Building Inspector", "number": "NSW #12345", "verified": true }]
      t.jsonb :credentials, default: []

      # Differentiators/selling points
      t.string :differentiators, array: true, default: []
      # e.g., ["same_day_response", "available_weekends", "same_day_reports", "free_consultation"]

      # Service guarantee statement
      t.text :guarantee_statement

      # Service areas (suburbs/postcodes)
      t.string :service_areas, array: true, default: []

      # Pricing information
      t.jsonb :pricing, default: {}
      # e.g., { "standard_inspection": { "price_cents": 45000, "description": "Standard building inspection" } }

      # Availability
      t.jsonb :availability, default: {}
      # e.g., { "weekdays": true, "weekends": true, "after_hours": false }

      # Response time commitment
      t.string :response_time_commitment # e.g., "same_day", "24_hours", "48_hours"

      # Insurance details
      t.string :public_liability_amount
      t.string :professional_indemnity_amount

      # Verification status
      t.string :verification_status, default: "pending"
      t.datetime :verified_at
      t.text :verification_notes

      # Platform status
      t.boolean :accepting_new_clients, default: true
      t.boolean :featured, default: false
      t.datetime :featured_until

      # Statistics (updated periodically)
      t.integer :total_jobs_completed, default: 0
      t.decimal :average_rating, precision: 3, scale: 2
      t.integer :total_reviews, default: 0

      # Soft delete
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :service_provider_profiles, :service_type
    add_index :service_provider_profiles, :verification_status
    add_index :service_provider_profiles, :accepting_new_clients
    add_index :service_provider_profiles, :featured
    add_index :service_provider_profiles, :service_areas, using: :gin
    add_index :service_provider_profiles, :abn, unique: true, where: "abn IS NOT NULL AND deleted_at IS NULL"
    add_index :service_provider_profiles, :deleted_at
    add_index :service_provider_profiles, [:average_rating, :total_reviews]
  end
end
