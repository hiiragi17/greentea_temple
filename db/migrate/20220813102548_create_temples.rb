class CreateTemples < ActiveRecord::Migration[7.0]
  def change
    create_table :temples do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.string :phone_number
      t.string :address, null: false
      t.string :access, null: false
      t.string :business_hours
      t.string :homepage
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.string :holiday
      t.string :img

      t.timestamps
    end
  end
end
