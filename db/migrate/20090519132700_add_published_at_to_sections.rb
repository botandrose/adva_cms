class AddPublishedAtToSections < ActiveRecord::Migration[7.0]
  def self.up
    add_column :sections, :published_at, :datetime
    # Removed data backfill using models. Keep migrations schema-only.
  end

  def self.down
    remove_column :sections, :published_at
  end
end
