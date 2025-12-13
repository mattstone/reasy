class CreatePostcodeProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :postcode_profiles do |t|
      t.string :postcode
      t.string :state
      t.string :locality
      t.decimal :latitude
      t.decimal :longitude
      t.integer :population
      t.integer :median_age
      t.bigint :median_household_income_cents
      t.bigint :median_house_price_cents
      t.bigint :median_unit_price_cents
      t.bigint :median_land_value_cents
      t.decimal :avg_household_size
      t.decimal :owner_occupied_pct
      t.decimal :rented_pct
      t.decimal :mortgage_pct
      t.decimal :unemployment_rate
      t.decimal :university_educated_pct
      t.decimal :professional_occupation_pct
      t.decimal :families_with_children_pct
      t.integer :seifa_advantage_disadvantage
      t.integer :seifa_economic_resources
      t.integer :seifa_education_occupation
      t.string :data_source
      t.integer :data_year
      t.datetime :last_updated_at

      t.timestamps
    end
    add_index :postcode_profiles, :postcode, unique: true
    add_index :postcode_profiles, :state
    add_index :postcode_profiles, [:latitude, :longitude]
  end
end
