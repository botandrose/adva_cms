require "has_counter/version"
require "active_record/has_counter"
ActiveRecord::Base.send :include, ActiveRecord::HasCounter
