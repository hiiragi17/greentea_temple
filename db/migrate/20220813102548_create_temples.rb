class CreateTemples < ActiveRecord::Migration[7.0]
  def change
    create_table :temples do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.string :phone_number
      t.string :address, null: false
      t.string :access, null: false
      t.datetime :open_time
      t.datetime :close_time
      t.string :homepage
      t.integer :latitude, null: false
      t.integer :longitude, null: false
      t.integer :holiday
      t.integer :img

      t.timestamps
    end
  end
end
