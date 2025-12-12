# frozen_string_literal: true

class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      # Who wrote the review
      t.references :reviewer, null: false, foreign_key: { to_table: :users }, index: true

      # Who is being reviewed
      t.references :reviewee, null: false, foreign_key: { to_table: :users }, index: true

      # What role is being reviewed: buyer, seller, service_provider
      t.string :reviewee_role, null: false

      # Optional link to transaction
      t.bigint :transaction_id

      # Ratings
      t.integer :overall_rating, null: false # 1-5

      # Category-specific ratings stored as JSONB
      # e.g., { "communication": 4, "reliability": 5, "professionalism": 4 }
      t.jsonb :category_ratings, default: {}

      # Review content
      t.string :title
      t.text :body, null: false

      # Status: pending, held, published, removed, disputed
      t.string :status, default: "pending", null: false

      # 48-hour hold for negative reviews
      t.datetime :hold_until
      t.string :hold_reason

      # Public response from reviewee
      t.text :public_response
      t.datetime :public_response_at

      # Admin notes (not visible to users)
      t.text :admin_notes

      # Soft delete
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :reviews, :reviewee_role
    add_index :reviews, :transaction_id
    add_index :reviews, :overall_rating
    add_index :reviews, :status
    add_index :reviews, :hold_until
    add_index :reviews, :deleted_at
    add_index :reviews, [:reviewee_id, :reviewee_role]

    # Review disputes
    create_table :review_disputes do |t|
      t.references :review, null: false, foreign_key: true, index: true

      # Who filed the dispute
      t.references :disputed_by, null: false, foreign_key: { to_table: :users }, index: true

      # Reason: false_information, inappropriate_content, wrong_person, other
      t.string :reason, null: false
      t.text :explanation, null: false

      # Evidence/attachments stored as JSONB array
      t.jsonb :evidence, default: []

      # Status: pending, under_review, upheld, rejected
      t.string :status, default: "pending", null: false

      # Admin handling
      t.text :admin_notes
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.datetime :resolved_at
      t.text :resolution_notes

      t.timestamps
    end

    add_index :review_disputes, :reason
    add_index :review_disputes, :status
  end
end
