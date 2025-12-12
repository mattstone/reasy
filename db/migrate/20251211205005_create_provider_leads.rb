class CreateProviderLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :provider_leads do |t|
      t.references :service_provider_profile, null: false, foreign_key: true
      t.references :property, foreign_key: true
      t.references :user, null: false, foreign_key: true  # The buyer/seller who needs service
      t.string :status, default: "new", null: false
      t.string :source, default: "platform"  # platform, referral, ai_recommendation
      t.string :service_type, null: false
      t.text :notes
      t.text :requirements
      t.datetime :contacted_at
      t.datetime :expires_at
      t.integer :priority, default: 0

      t.timestamps
    end

    add_index :provider_leads, :status
    add_index :provider_leads, :service_type
    add_index :provider_leads, :expires_at
  end
end
