class CreateRouteSpots < ActiveRecord::Migration[7.0]
  def change
    create_table :route_spots do |t|
      t.references :route, null: false, foreign_key: true
      t.references :spottable, polymorphic: true, null: false
      t.integer :position, null: false
      t.integer :transport

      t.timestamps
    end

    add_index :route_spots, %i[route_id position]
  end
end
