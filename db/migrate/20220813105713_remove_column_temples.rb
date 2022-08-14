class RemoveColumnTemples < ActiveRecord::Migration[7.0]
  def change
    remove_column :temples, :holiday, :integer
    remove_column :temples, :img, :integer
  end
end
