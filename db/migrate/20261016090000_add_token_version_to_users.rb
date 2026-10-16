class AddTokenVersionToUsers < ActiveRecord::Migration[8.1]
  def change
    # JWT に載せて照合する世代番号。ログアウト時にインクリメントし、旧トークンを一括失効させる。
    add_column :users, :token_version, :integer, default: 0, null: false
  end
end
