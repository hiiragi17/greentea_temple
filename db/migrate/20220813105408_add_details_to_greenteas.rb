class AddDetailsToGreenteas < ActiveRecord::Migration[7.0]
  def change
    add_column :greenteas, :holiday, :string
    add_column :greenteas, :img, :string
  end
end
