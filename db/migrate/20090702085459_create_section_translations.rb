class CreateSectionTranslations < ActiveRecord::Migration[7.0]
  def self.up
    # Removed model-dependent translation table creation to keep migration schema-only.
  end

  def self.down
    # No-op
  end
end
