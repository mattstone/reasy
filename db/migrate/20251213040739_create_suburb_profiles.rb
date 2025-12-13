class CreateSuburbProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :suburb_profiles do |t|
      t.string :suburb
      t.string :postcode
      t.string :state
      t.decimal :latitude
      t.decimal :longitude
      t.integer :population
      t.integer :median_age
      t.bigint :median_household_income_cents
      t.bigint :median_house_price_cents
      t.bigint :median_unit_price_cents
      t.bigint :median_land_value_cents
      t.decimal :house_price_growth_1yr
      t.decimal :house_price_growth_5yr
      t.decimal :unit_price_growth_1yr
      t.decimal :unit_price_growth_5yr
      t.decimal :rental_yield_house
      t.decimal :rental_yield_unit
      t.integer :days_on_market_house
      t.integer :days_on_market_unit
      t.integer :sales_volume_12m
      t.decimal :avg_household_size
      t.decimal :owner_occupied_pct
      t.decimal :rented_pct
      t.integer :seifa_score
      t.string :school_catchment_primary
      t.string :school_catchment_secondary
      t.integer :data_year
      t.datetime :last_updated_at

      t.timestamps
    end
    add_index :suburb_profiles, [:suburb, :state], unique: true
    add_index :suburb_profiles, :postcode
    add_index :suburb_profiles, :state
    add_index :suburb_profiles, [:latitude, :longitude]
  end
end
