class CreateTempleLikes < ActiveRecord::Migration[7.0]
  def change
    create_table :temple_likes do |t|
      t.references :user, foreign_key: true
      t.references :temple, foreign_key: true

      t.timestamps
    end
    add_index  :temple_likes, [:user_id, :temple_id], unique: true
  end
end
