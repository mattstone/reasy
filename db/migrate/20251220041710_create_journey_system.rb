class CreateJourneySystem < ActiveRecord::Migration[8.1]
  def change
    # Journey Checklists - Master templates for buyer/seller/service_provider journeys
    create_table :journey_checklists do |t|
      t.string :journey_type, null: false  # buyer, seller, service_provider
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 0
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :journey_checklists, :journey_type
    add_index :journey_checklists, :active

    # Checklist Items - Individual items within a checklist
    create_table :checklist_items do |t|
      t.references :journey_checklist, null: false, foreign_key: true
      t.string :key, null: false           # unique identifier e.g., "finance_approved"
      t.string :title, null: false
      t.text :description
      t.text :help_text                    # AI can explain this
      t.text :why_important                # Octalysis: Epic Meaning
      t.integer :points, default: 10       # Octalysis: Accomplishment
      t.integer :position, default: 0
      t.string :category                   # pre_offer, due_diligence, settlement, etc.
      t.string :required_for_next          # blocks which item if not done
      t.boolean :requires_document, default: false
      t.string :document_types, array: true, default: []
      t.boolean :requires_service_provider, default: false
      t.string :service_provider_types, array: true, default: []
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :checklist_items, :key
    add_index :checklist_items, :category
    add_index :checklist_items, [:journey_checklist_id, :position]

    # User Checklist Progress - User's progress on items
    create_table :user_checklist_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :checklist_item, null: false, foreign_key: true
      t.references :context, polymorphic: true  # Property, Transaction, ProviderJob
      t.string :status, default: "pending"  # pending, in_progress, completed, skipped
      t.datetime :started_at
      t.datetime :completed_at
      t.text :notes
      t.jsonb :metadata, default: {}       # store AI analysis results, etc.
      t.timestamps
    end

    add_index :user_checklist_progresses, :status
    add_index :user_checklist_progresses, [:user_id, :checklist_item_id, :context_type, :context_id],
              unique: true, name: "idx_user_checklist_progress_unique"

    # User Achievements - Gamification rewards
    create_table :user_achievements do |t|
      t.references :user, null: false, foreign_key: true
      t.string :achievement_type, null: false  # milestone, streak, speed_bonus, level_up, etc.
      t.string :title, null: false
      t.text :description
      t.integer :points_earned, default: 0
      t.string :badge_icon                     # emoji or icon class
      t.references :context, polymorphic: true
      t.datetime :earned_at
      t.timestamps
    end

    add_index :user_achievements, :achievement_type
    add_index :user_achievements, :earned_at

    # Contract Analyses - AI analysis of uploaded contracts
    create_table :contract_analyses do |t|
      t.references :property_document, null: false, foreign_key: true
      t.references :analyzed_by, foreign_key: { to_table: :users }  # AI or human
      t.string :document_type                   # contract_of_sale, section_32, etc.
      t.text :extracted_text                    # Full text extracted from PDF
      t.jsonb :extracted_terms, default: {}     # parties, price, settlement date, etc.
      t.jsonb :unusual_clauses, default: []     # array of {clause, risk_level, explanation}
      t.string :overall_risk_level              # low, medium, high
      t.text :summary
      t.text :recommendations
      t.integer :tokens_used, default: 0
      t.string :analysis_status, default: "pending"  # pending, processing, completed, failed
      t.text :error_message
      t.timestamps
    end

    add_index :contract_analyses, :analysis_status
    add_index :contract_analyses, :overall_risk_level

    # Transaction Milestones - Shared visibility between buyer/seller
    create_table :transaction_milestones do |t|
      t.references :transaction, null: false, foreign_key: { to_table: :transactions }
      t.string :milestone_type, null: false     # finance_approved, inspection_passed, etc.
      t.string :title, null: false
      t.text :description
      t.string :visible_to, null: false         # buyer, seller, both
      t.references :completed_by, foreign_key: { to_table: :users }
      t.datetime :completed_at
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :transaction_milestones, :milestone_type
    add_index :transaction_milestones, :visible_to
    add_index :transaction_milestones, [:transaction_id, :milestone_type], unique: true
  end
end
