class ChangeDatatypeLatitudeOfTemples < ActiveRecord::Migration[7.0]
  def change
    change_column :temples, :latitude, :float
    change_column :temples, :longitude, :float
  end
end
