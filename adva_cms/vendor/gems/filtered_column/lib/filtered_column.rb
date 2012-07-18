require "filtered_column/version"
require "filtered_column/processor"
require "filtered_column/mixin"
require "filtered_column/filters/base"
require "filtered_column/macros/base"

require "filtered_column/filters/smartypants_filter"
require "filtered_column/filters/textile_filter"
FilteredColumn.filters[:smartypants_filter] = FilteredColumn::Filters::SmartypantsFilter
FilteredColumn.filters[:textile_filter] = FilteredColumn::Filters::TextileFilter

# don't even bother until there are default macros
#Dir["#{File.dirname(__FILE__)}/filtered_column/macros/*_macro.rb"].sort.each do |macro_name|
#  FilteredColumn.macros.update(File.basename(macro_name).sub(/\.rb/, '').to_sym => nil)
#end

ActiveRecord::Base.send(:include, FilteredColumn::Mixin)
