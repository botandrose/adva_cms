class CreateContentsTable < ActiveRecord::Migration[7.0]
  def self.up
    create_table :contents, :force => true do |t|
      t.references :site
      t.references :section
      t.string     :type, :limit => 20
      t.integer    :position

      t.string     :permalink
      t.text       :excerpt_html
      t.text       :body_html

      t.references :author, :polymorphic => true
      t.string     :author_name, :limit => 40
      t.string     :author_email, :limit => 40
      t.string     :author_homepage

      t.integer    :version
      t.string     :filter
      t.integer    :comment_age, :default => 0
      t.string     :cached_tag_list
      t.integer    :assets_count, :default => 0

      t.datetime   :published_at
      t.timestamps
    end
    # Removed model-dependent translation table creation. Migrations should be
    # schema-only. If a translation table is needed, add a dedicated schema
    # migration that does not depend on model code.
  end

  def self.down
    drop_table :contents
    # No-op: do not attempt to drop model-managed translation tables here.
  end
end
