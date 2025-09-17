class AddTitleToContents < ActiveRecord::Migration[7.0]
  def change
    add_column :contents, :title, :string
    add_column :contents, :body, :text
    add_column :contents, :excerpt, :text
  end
end
