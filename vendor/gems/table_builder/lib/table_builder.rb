require "table_builder/version"

require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/try'

require 'table_builder/tag'
require 'table_builder/cell'
require 'table_builder/row'
require 'table_builder/rows'
require 'table_builder/body'
require 'table_builder/head'
require 'table_builder/foot'
require 'table_builder/column'
require 'table_builder/table'

module TableBuilder
  mattr_accessor :options
  self.options = { 
    :alternate_rows => true,
    :i18n_scope => nil
  }

  def table_for(collection = [], options = {}, &block)
    output = Table.new(self, collection, options, &block).render
    if respond_to?(:concat)
      concat(output)
      nil
    else
      output
    end
  end
end

TableBuilder.options[:i18n_scope] = :adva
require 'erb'
