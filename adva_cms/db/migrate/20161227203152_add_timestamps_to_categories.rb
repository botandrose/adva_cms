class AddTimestampsToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :created_at, :timestamp
    add_column :categories, :updated_at, :timestamp
  end
end
