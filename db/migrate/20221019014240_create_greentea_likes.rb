class CreateGreenteaLikes < ActiveRecord::Migration[7.0]
  def change
    create_table :greentea_likes do |t|
      t.references :user, foreign_key: true
      t.references :greentea, foreign_key: true

      t.timestamps
    end
    add_index  :greentea_likes, [:user_id, :greentea_id], unique: true
  end
end
