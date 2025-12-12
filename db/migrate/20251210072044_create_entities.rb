# frozen_string_literal: true

class CreateEntities < ActiveRecord::Migration[8.1]
  def change
    create_table :entities do |t|
      t.references :user, null: false, foreign_key: true, index: true

      # Entity type: individual, company, smsf
      t.string :entity_type, null: false

      # Is this the user's default entity for transactions
      t.boolean :is_default, default: false, null: false

      # Verification status
      t.datetime :verified_at
      t.string :verification_status, default: "pending", null: false
      t.text :verification_notes

      # Common fields
      t.string :name, null: false
      t.string :email
      t.string :phone

      # Individual-specific fields
      t.date :date_of_birth
      # TFN is encrypted using Lockbox
      t.text :tfn_ciphertext
      t.string :tfn_bidx

      # Company-specific fields
      t.string :company_name
      t.string :abn
      t.string :acn
      t.text :registered_address
      t.string :director_names, array: true, default: []

      # SMSF-specific fields
      t.string :fund_name
      t.string :fund_abn
      t.string :trustee_names, array: true, default: []
      t.datetime :trust_deed_verified_at

      # Soft delete
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :entities, :entity_type
    add_index :entities, :is_default
    add_index :entities, :verification_status
    add_index :entities, :abn, unique: true, where: "abn IS NOT NULL AND deleted_at IS NULL"
    add_index :entities, :acn, unique: true, where: "acn IS NOT NULL AND deleted_at IS NULL"
    add_index :entities, :fund_abn, unique: true, where: "fund_abn IS NOT NULL AND deleted_at IS NULL"
    add_index :entities, :tfn_bidx, unique: true, where: "tfn_bidx IS NOT NULL AND deleted_at IS NULL"
    add_index :entities, :deleted_at
    add_index :entities, [:user_id, :is_default], where: "is_default = true AND deleted_at IS NULL"
  end
end
