require "friendly_id"

ActiveRecord::Base.class_eval do
  def self.has_permalink column, options={}
    extend FriendlyId

    friendly_id column do |config|
      config.use :slugged
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
  end
end
