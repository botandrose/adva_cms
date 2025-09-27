ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.column :name, :string
    t.column :first_name, :string
    t.column :last_name, :string
    t.column :password_hash, :string, :limit => 40
    t.column :password_salt, :string, :limit => 40
    t.column :token_key, :string, :limit => 40
    t.column :token_expiration, :datetime
    t.column :remember_me, :string, :limit => 40
  end
end
