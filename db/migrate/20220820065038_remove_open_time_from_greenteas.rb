class RemoveOpenTimeFromGreenteas < ActiveRecord::Migration[7.0]
  def change
    remove_column :greenteas, :open_time, :datatime
    remove_column :greenteas, :close_time, :datatime
  end
end
