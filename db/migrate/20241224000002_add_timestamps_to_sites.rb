class AddTimestampsToSites < ActiveRecord::Migration[7.0]
  def change
    add_timestamps :sites
  end
end