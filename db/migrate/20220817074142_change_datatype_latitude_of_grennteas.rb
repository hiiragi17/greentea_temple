class ChangeDatatypeLatitudeOfGrennteas < ActiveRecord::Migration[7.0]
  def change
    change_column :greenteas, :latitude, :float
    change_column :greenteas, :longitude, :float
  end
end
