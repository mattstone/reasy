class AddJourneyFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :preferred_agent, :string
    add_column :users, :journey_points, :integer, default: 0, null: false
    add_column :users, :journey_level, :integer, default: 1, null: false
    add_column :users, :journey_title, :string, default: "Property Newcomer", null: false

    add_index :users, :preferred_agent
  end
end
