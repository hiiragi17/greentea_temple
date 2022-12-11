class CreateTemplecomments < ActiveRecord::Migration[7.0]
  def change
    create_table :templecomments do |t|
      t.text :body, null: false
      t.references :user, null: false, foreign_key: true
      t.references :temple, null: false, foreign_key: true

      t.timestamps
    end
  end
end
