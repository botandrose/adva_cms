module Adva
  module HasOptions
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        class_attribute :option_definitions, default: {}
        serialize :options
      end
    end

    module ClassMethods
      def has_option(*names)
        definition = names.extract_options!
        names.each do |name|
          self.option_definitions[name] = definition.reverse_update(:default => nil, :type => :text_field)
          class_eval <<-src, __FILE__, __LINE__
            def #{name}
              #{name}_before_type_cast
            end

            def #{name}_before_type_cast
              self.options ||= {}
              options.key?(:#{name}) ? options[:#{name}] : self.class.option_definition(:#{name}, :default)
            end

            def #{name}=(value)
              options_will_change!
              if self.class.option_definition(:#{name}, :type) == :boolean
                value = ActiveRecord::Type::Boolean.new.cast(value)
              end
              self.options ||= {}
              options[:#{name}] = value
            end
          src
        end
      
        def option_definition(name, key)
          option_definitions[name][key]
        rescue
          superclass.option_definition(name, key) unless self.class.superclass == ActiveRecord::Base
        end
      end
    end
  end
end

