# frozen_string_literal: true

class CreateOffersAndTransactions < ActiveRecord::Migration[8.1]
  def change
    # Offers on properties
    create_table :offers do |t|
      t.references :property, null: false, foreign_key: true, index: true
      t.references :buyer, null: false, foreign_key: { to_table: :users }, index: true
      t.references :buyer_entity, foreign_key: { to_table: :entities }

      # Offer amount
      t.integer :amount_cents, null: false
      t.string :currency, default: "AUD"

      # Finance details
      t.string :finance_type, null: false  # cash, pre_approved, subject_to_finance
      t.string :finance_lender
      t.integer :deposit_cents
      t.integer :deposit_percentage

      # Settlement
      t.integer :settlement_days, null: false
      t.date :proposed_settlement_date

      # Conditions
      t.boolean :subject_to_finance, default: false
      t.boolean :subject_to_building_inspection, default: false
      t.boolean :subject_to_pest_inspection, default: false
      t.boolean :subject_to_valuation, default: false
      t.boolean :subject_to_sale_of_property, default: false
      t.text :other_conditions

      # NSW Cooling-off
      t.boolean :cooling_off_waived, default: false
      t.datetime :cooling_off_ends_at

      # Status: draft, submitted, viewed, countered, accepted, rejected, withdrawn, expired
      t.string :status, null: false, default: "draft"

      # Timestamps for status changes
      t.datetime :submitted_at
      t.datetime :viewed_at
      t.datetime :responded_at
      t.datetime :accepted_at
      t.datetime :rejected_at
      t.datetime :withdrawn_at
      t.datetime :expires_at

      # Response
      t.text :seller_response
      t.references :counter_offer, foreign_key: { to_table: :offers }

      # Soft delete
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :offers, :status
    add_index :offers, :finance_type
    add_index :offers, :submitted_at
    add_index :offers, :expires_at
    add_index :offers, :deleted_at

    # Transactions (when offer is accepted)
    create_table :transactions do |t|
      t.references :property, null: false, foreign_key: true, index: true
      t.references :offer, null: false, foreign_key: true, index: true
      t.references :seller, null: false, foreign_key: { to_table: :users }, index: true
      t.references :buyer, null: false, foreign_key: { to_table: :users }, index: true
      t.references :seller_entity, foreign_key: { to_table: :entities }
      t.references :buyer_entity, foreign_key: { to_table: :entities }

      # Transaction amount
      t.integer :sale_price_cents, null: false
      t.integer :deposit_cents
      t.integer :deposit_paid_cents, default: 0

      # Status: pending, exchanged, cooling_off, unconditional, settling, settled, fallen_through
      t.string :status, null: false, default: "pending"

      # Key dates
      t.date :exchange_date
      t.date :settlement_date
      t.datetime :cooling_off_ends_at
      t.datetime :conditions_due_at

      # Condition satisfaction
      t.boolean :finance_approved, default: false
      t.datetime :finance_approved_at
      t.boolean :building_inspection_passed, default: false
      t.datetime :building_inspection_at
      t.boolean :pest_inspection_passed, default: false
      t.datetime :pest_inspection_at

      # Completion
      t.datetime :settled_at
      t.datetime :fallen_through_at
      t.text :fallen_through_reason

      # Service providers involved
      t.references :buyer_conveyancer, foreign_key: { to_table: :users }
      t.references :seller_conveyancer, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :transactions, :status
    add_index :transactions, :exchange_date
    add_index :transactions, :settlement_date
    add_index :transactions, :settled_at

    # Transaction timeline events
    create_table :transaction_events do |t|
      t.references :transaction, null: false, foreign_key: true, index: true
      t.references :user, foreign_key: true

      t.string :event_type, null: false
      t.string :title, null: false
      t.text :description
      t.jsonb :metadata, default: {}

      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :transaction_events, :event_type
    add_index :transaction_events, :occurred_at
  end
end
