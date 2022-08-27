class CreateGreenteaGenres < ActiveRecord::Migration[7.0]
  def change
    create_table :greentea_genres do |t|
      t.references :greentea, null: false, foreign_key: true
      t.references :genre, null: false, foreign_key: true
      
      t.timestamps
    end
  end
end
