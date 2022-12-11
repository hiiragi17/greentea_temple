class CreateGreenteacomments < ActiveRecord::Migration[7.0]
  def change
    create_table :greenteacomments do |t|
      t.text :body, null: false
      t.references :user, null: false, foreign_key: true
      t.references :greentea, null: false, foreign_key: true

      t.timestamps
    end
  end
end
