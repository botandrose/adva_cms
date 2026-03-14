class AddHiddenOnGlobalNavToSections < ActiveRecord::Migration[7.0]
  def change
    add_column :sections, :hidden_on_global_nav, :boolean, default: false
  end
end
