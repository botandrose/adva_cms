class Tagging < ActiveRecord::Base #:nodoc:
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true
  
  after_destroy do
    tag.destroy if Tag.destroy_unused && tag.taggings.count.zero?
  end
end
