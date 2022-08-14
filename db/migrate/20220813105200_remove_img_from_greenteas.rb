class RemoveImgFromGreenteas < ActiveRecord::Migration[7.0]
  def change
    remove_column :greenteas, :img, :integer
  end
end
