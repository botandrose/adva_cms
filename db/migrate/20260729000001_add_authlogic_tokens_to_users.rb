class AddAuthlogicTokensToUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :persistence_token, :string
    add_column :users, :perishable_token, :string

    # Authlogic validates presence of persistence_token and looks sessions up by
    # it, so existing rows need one before they can log in again. Byte counts
    # match Authlogic::Random.hex_token and friendly_token respectively.
    backfill :persistence_token, 64
    backfill :perishable_token, 15

    change_column_null :users, :persistence_token, false

    add_index :users, :persistence_token, unique: true
    add_index :users, :perishable_token, unique: true
  end

  def down
    remove_index :users, :perishable_token
    remove_index :users, :persistence_token
    remove_column :users, :perishable_token
    remove_column :users, :persistence_token
  end

  private

    def backfill(column, byte_length)
      select_values("SELECT id FROM users").each do |id|
        execute <<~SQL
          UPDATE users
          SET #{quote_column_name(column)} = #{quote(SecureRandom.hex(byte_length))}
          WHERE id = #{quote(id)}
        SQL
      end
    end
end
