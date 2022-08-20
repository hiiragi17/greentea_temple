class RemoveOpenTimeFromTemples < ActiveRecord::Migration[7.0]
  def change
    remove_column :temples, :open_time, :datatime
    remove_column :temples, :close_time, :datatime
  end
end
