class WidenUsersPasswordHash < ActiveRecord::Migration[7.0]
  # bcrypt hashes are 60 chars; the legacy SHA1 column only held 40.
  def up
    change_column :users, :password_hash, :string, limit: nil
    change_column_null :users, :password_salt, true
  end

  def down
    change_column :users, :password_hash, :string, limit: 40
  end
end
