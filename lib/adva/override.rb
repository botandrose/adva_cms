module Adva
  module Override
    class << self
      def call(controller: nil, model: nil, &block)
        if controller
          override_class("app/controllers/#{controller}_controller.rb", &block)
        elsif model
          override_class("app/models/#{model}.rb", &block)
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

      def override_class(class_path, &block)
        require_dependency File.expand_path(class_path, Gem.loaded_specs['adva'].full_gem_path)
        class_name = path_to_class_name(class_path)
        mod = Module.new(&block)
        (@override_modules ||= []) << mod
        class_name.constantize.prepend(mod)
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
