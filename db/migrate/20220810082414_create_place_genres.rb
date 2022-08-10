class CreatePlaceGenres < ActiveRecord::Migration[7.0]
  def change
    create_table :place_genres do |t|
      t.references :place, null: false, foreign_key: true
      t.references :genre, null: false, foreign_key: true

      t.timestamps
    end
  end
end
