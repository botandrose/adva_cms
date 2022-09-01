class Categorization < ActiveRecord::Base
  belongs_to :categorizable, :polymorphic => true, touch: true
  belongs_to :category, touch: true
end
