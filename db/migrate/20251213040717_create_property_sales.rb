class CreatePropertySales < ActiveRecord::Migration[8.1]
  def change
    create_table :property_sales do |t|
      t.string :property_id
      t.string :address
      t.string :unit_number
      t.string :street_number
      t.string :street_name
      t.string :suburb
      t.string :postcode
      t.string :state
      t.decimal :latitude
      t.decimal :longitude
      t.string :property_type
      t.bigint :sale_price_cents
      t.date :contract_date
      t.date :settlement_date
      t.decimal :land_area_sqm
      t.decimal :building_area_sqm
      t.integer :bedrooms
      t.integer :bathrooms
      t.integer :parking
      t.integer :year_built
      t.string :zoning
      t.bigint :land_value_cents
      t.date :land_value_date
      t.boolean :strata_lot
      t.string :data_source
      t.string :source_id

      t.timestamps
    end
    add_index :property_sales, :property_id
    add_index :property_sales, :suburb
    add_index :property_sales, :postcode
    add_index :property_sales, :property_type
    add_index :property_sales, :contract_date
    add_index :property_sales, :source_id, unique: true
    add_index :property_sales, [:latitude, :longitude]
    add_index :property_sales, :state
  end
end
