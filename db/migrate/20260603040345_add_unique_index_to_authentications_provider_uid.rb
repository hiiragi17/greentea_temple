class AddUniqueIndexToAuthenticationsProviderUid < ActiveRecord::Migration[7.1]
  def change
    remove_index :authentications, name: 'index_authentications_on_provider_and_uid'
    add_index :authentications, %i[provider uid], unique: true
  end
end
