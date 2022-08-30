class CreateTempleAreas < ActiveRecord::Migration[7.0]
  def change
    create_table :temple_areas do |t|
      t.references :temple, null: false, foreign_key: true
      t.references :area, null: false, foreign_key: true

      t.timestamps
    end
  end
end
