require "friendly_id"

module Adva
  module HasPermalink
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def has_permalink column, options={}
        extend FriendlyId

        friendly_id column do |config|
          config.use :slugged, :finders
          if options[:scope]
            config.use :scoped
            config.scope = options[:scope]
          end
          config.slug_column = options[:url_attribute]
        end

        self.class_eval do
          def should_generate_new_friendly_id?
            permalink.blank?
          end
        end

        define_method :"#{options[:url_attribute]}=" do |value|
          value = value.parameterize if value
          super value
        end
      end
    end
  end
end

