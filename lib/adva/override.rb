module Adva
  module Override
    class << self
      def call(controller: nil, model: nil, gem: "adva", &block)
        if controller
          override_class("app/controllers/#{controller}_controller.rb", gem: gem, &block)
        elsif model
          override_class("app/models/#{model}.rb", gem: gem, &block)
        else
          raise ArgumentError, "Must specify either controller: or model:"
        end
      end

      def reset!
        @override_modules&.each do |mod|
          mod.instance_methods.each { |m| mod.remove_method(m) }
        end
        @override_modules = []
      end

      private

      def override_class(class_path, gem:, &block)
        require_dependency File.expand_path(class_path, Gem.loaded_specs[gem].full_gem_path)
        class_name = path_to_class_name(class_path)
        klass = class_name.constantize

        mod = Module.new do
          extend ActiveSupport::Concern
          module_eval(&block)
        end
        (@override_modules ||= []) << mod

        klass.prepend(mod)
        klass.singleton_class.prepend(mod::ClassMethods) if mod.const_defined?(:ClassMethods, false)
        klass.class_eval(&mod.instance_variable_get(:@_included_block)) if mod.instance_variable_defined?(:@_included_block)
      end

      def path_to_class_name(path)
        path.sub('app/controllers/', '')
            .sub('app/models/', '')
            .sub(/\.rb$/, '')
            .camelize
            .gsub('/', '::')
      end
    end
  end

  def self.override(**args, &block)
    Override.call(**args, &block)
  end
end
