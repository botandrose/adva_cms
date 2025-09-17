class MoveSectionsToPages < ActiveRecord::Migration[7.0]
  def self.up
    execute "UPDATE sections SET type = 'Page' WHERE type = 'Section' OR type IS NULL"
  end

  def self.down
    execute "UPDATE sections SET type = NULL WHERE type = 'Page'"
  end
end
