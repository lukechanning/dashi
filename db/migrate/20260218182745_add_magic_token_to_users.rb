class AddMagicTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :magic_token, :string
    add_index :users, :magic_token, unique: true
    add_column :users, :magic_token_expires_at, :datetime
  end
end
