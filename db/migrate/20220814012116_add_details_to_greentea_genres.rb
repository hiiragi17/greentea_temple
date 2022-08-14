class AddDetailsToGreenteaGenres < ActiveRecord::Migration[7.0]
  def change
    add_column :greentea_genres, :name, :string, null: false
  end
end
