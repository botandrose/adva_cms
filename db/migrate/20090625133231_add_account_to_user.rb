class AddAccountToUser < ActiveRecord::Migration[7.0]
  def self.up
    add_column  :users, :account_id, :integer
    add_index   :users, :account_id
  end

  def self.down
    remove_column :users, :account_id
  end
end
