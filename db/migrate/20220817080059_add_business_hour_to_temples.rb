class AddBusinessHourToTemples < ActiveRecord::Migration[7.0]
  def change
    add_column :temples, :business_hours, :string
  end
end
