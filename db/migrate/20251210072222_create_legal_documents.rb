# frozen_string_literal: true

class CreateLegalDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :legal_documents do |t|
      # Document type: terms_and_conditions, privacy_policy
      t.string :document_type, null: false

      # Version info
      t.string :version, null: false
      t.boolean :is_current, default: false, null: false

      # Content
      t.string :title, null: false
      t.text :content, null: false
      t.text :summary # Brief description of changes from previous version

      # Publishing
      t.datetime :published_at
      t.boolean :requires_acceptance, default: true, null: false

      # Metadata
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :published_by, foreign_key: { to_table: :users }

      # Draft status
      t.boolean :is_draft, default: true, null: false

      t.timestamps
    end

    add_index :legal_documents, [:document_type, :version], unique: true
    add_index :legal_documents, [:document_type, :is_current], where: "is_current = true"
    add_index :legal_documents, :published_at

    # Track user acceptances
    create_table :legal_document_acceptances do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :legal_document, null: false, foreign_key: true, index: true

      # Context of acceptance
      t.string :ip_address
      t.text :user_agent

      t.datetime :accepted_at, null: false

      t.timestamps
    end

    add_index :legal_document_acceptances, [:user_id, :legal_document_id], unique: true, name: "idx_legal_acceptances_user_document"
  end
end
