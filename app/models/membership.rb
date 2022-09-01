class Membership < ActiveRecord::Base
  belongs_to :site
  belongs_to :user

  validates_uniqueness_of :site_id, scope: :user_id, case_sensitive: true
end
