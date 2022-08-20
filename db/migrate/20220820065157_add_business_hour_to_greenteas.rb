class AddBusinessHourToGreenteas < ActiveRecord::Migration[7.0]
  def change
    add_column :greenteas, :business_hours, :string
  end
end
