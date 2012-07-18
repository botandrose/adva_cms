require "has_filter/version"
require 'has_filter/filter'
require 'has_filter/active_record/act_macro'

module HasFilter
  module Helper
    def filter_for(klass, options = {})
      form_tag(options.delete(:url) || request.path, :method => :get, :id => 'filters', :class => 'filters') do
        klass.filter_chain.to_form_fields(self, options).join("\n") + "\n" +
        content_tag(:div, :class => 'submit') do
          content_tag(:button, I18n.t(:'filter.submit.value', :default => 'Apply'))
          # link_to I18n.t(:'filter.submit.value', :default => 'Apply'), :href => '#'
        end
      end
    end
  end

  class Engine < Rails::Engine
  end
end

ActiveRecord::Base.send :extend, HasFilter::ActiveRecord::ActMacro
ActionController::Base.send :helper, HasFilter::Helper
