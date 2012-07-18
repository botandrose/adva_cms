require "belongs_to_cacheable/version"
require "active_record/belongs_to_cacheable"
ActiveRecord::Base.send :include, ActiveRecord::BelongsToCacheable
