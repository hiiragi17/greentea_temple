class CreateGreenteas < ActiveRecord::Migration[7.0]
  def change
    create_table :greenteas do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.string :phone_number
      t.string :address, null: false
      t.string :access, null: false
      t.string :business_hours
      t.string :homepage
      t.float :latitude
      t.float :longitude
      t.integer :closed
      t.string :holiday
      t.string :img

      t.timestamps
    end
  end
end
