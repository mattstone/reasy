class AddScoreWeightsToBuyerProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :buyer_profiles, :score_weights, :jsonb, default: {}, null: false
  end
end
