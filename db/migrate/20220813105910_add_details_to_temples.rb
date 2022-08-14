class AddDetailsToTemples < ActiveRecord::Migration[7.0]
  def change
    add_column :temples, :holiday, :string
    add_column :temples, :img, :string
  end
end
