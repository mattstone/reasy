class CreateProviderJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :provider_jobs do |t|
      t.references :service_provider_profile, null: false, foreign_key: true
      t.references :provider_lead, foreign_key: true
      t.references :property, foreign_key: true
      t.references :client, null: false, foreign_key: { to_table: :users }
      t.references :transaction, foreign_key: true
      t.string :status, default: "pending", null: false
      t.string :service_type, null: false
      t.string :title, null: false
      t.text :description
      t.text :requirements
      t.integer :quoted_price_cents
      t.integer :final_price_cents
      t.date :scheduled_date
      t.datetime :started_at
      t.datetime :completed_at
      t.text :completion_notes
      t.integer :client_rating
      t.text :client_review

      t.timestamps
    end

    add_index :provider_jobs, :status
    add_index :provider_jobs, :service_type
    add_index :provider_jobs, :scheduled_date
  end
end
