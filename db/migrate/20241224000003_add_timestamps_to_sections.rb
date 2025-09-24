class AddTimestampsToSections < ActiveRecord::Migration[7.0]
  def change
    add_timestamps :sections
  end
end