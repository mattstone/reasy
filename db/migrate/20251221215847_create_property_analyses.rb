class CreatePropertyAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :property_analyses do |t|
      t.references :property, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :match_score
      t.jsonb :strengths, default: []
      t.jsonb :considerations, default: []
      t.text :suggestion
      t.jsonb :ai_badges, default: []
      t.jsonb :context_snapshot, default: {}
      t.string :status, default: "pending"
      t.string :model_version
      t.datetime :expires_at
      t.datetime :analyzed_at

      t.timestamps
    end

    # Index for finding valid analysis for a user/property combo
    add_index :property_analyses, [:property_id, :user_id, :expires_at],
              name: "index_property_analyses_on_property_user_expires"

    # Index for cleanup jobs
    add_index :property_analyses, :expires_at
  end
end
