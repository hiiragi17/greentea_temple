class CreatePlaceAreas < ActiveRecord::Migration[7.0]
  def change
    create_table :place_areas do |t|
      t.references :place, null: false, foreign_key: true
      t.references :area, null: false, foreign_key: true

      t.timestamps
    end
  end
end
