class Delete < ActiveRecord::Migration[7.0]
  def change
    drop_table :place_areas
    drop_table :place_genres
    drop_table :places
    drop_table :areas
    drop_table :genres
  end
end
