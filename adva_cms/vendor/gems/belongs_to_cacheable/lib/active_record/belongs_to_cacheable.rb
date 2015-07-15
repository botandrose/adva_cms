module ActiveRecord
  module BelongsToCacheable
    def self.included(base)
      base.extend ActMacro
    end

    module ActMacro
      def belongs_to_cacheable(*args)
        options = args.extract_options!
        options.reverse_merge! :validate => true  # FIXME Content.author should not be polymorphic
        validate = options.delete :validate # TODO make this more flexible
        associations = args

        associations.each do |name|
          belongs_to name, :polymorphic => true
          if validate
            validates_presence_of name
            validates_associated  name
          end
          before_save :"cache_#{name}_attributes!"

          define_method :"cache_#{name}_attributes!" do
            if association = send(name)
              cached_attributes_for(name).each do |attribute|
                self[:"#{name}_#{attribute}"] = association.send(attribute)
              end
            end
          end

          define_method :"#{name}_with_default_instance" do
            send :"#{name}_without_default_instance" ||
              instantiate_from_cached_attributes(name)
          end
          alias_method_chain name, :default_instance

          define_method :"is_#{name}?" do |object|
            send(name) == object
          end

          @@cached_associations ||= []
          @@cached_associations << name

          define_singleton_method :define_attribute_methods do
            super()
            @@cached_associations.each do |name|
              cached_attributes_for(name).each do |attribute|
                define_method :"#{name}_#{attribute}" do
                  read_attribute(:"#{name}_#{attribute}") || send(name).try(attribute)
                end
              end
            end
          end
        end

        define_singleton_method :cached_attributes_for do |name|
          column_names.map do |attribute|
            attribute.to_s =~ /^#{name}_(.*)/ && !['id', 'type'].include?($1) ? $1 : nil
          end.compact
        end

        define_method :cached_attributes_for do |name|
          attributes.keys.map do |attribute|
            attribute.to_s =~ /^#{name}_(.*)/ && !['id', 'type'].include?($1) ? $1 : nil
          end.compact
        end

        define_method :instantiate_from_cached_attributes do |name, attributes|
          if type = respond_to?(:"#{name}_type") ? send(:"#{name}_type") : name.classify
            type.constantize.new.tap do |object|
              attributes.each do |attribute|
                object.send :"#{attribute}=", send(:"#{name}_#{attribute}")
              end
            end
          end
        end
      end
    end
  end
end
