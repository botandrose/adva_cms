module Rails
  def self.plugins
    @plugins ||= begin
      # Minimal registry with a single test plugin used by specs
      test_plugin = Rails::Plugin.new('test_plugin')
      { test_plugin: test_plugin }
    end
  end

  class Plugin
    attr_accessor :name, :directory, :owner

    def initialize(name, directory: nil)
      @name = name.to_s
      @directory = directory || @name
    end

    def clone
      self.class.new(name, directory: directory)
    end

    def save!
      cfg = config
      cfg.name = name
      cfg.site = owner
      cfg.save!
      true
    end

    def config
      @config ||= begin
        raise 'owner must be set before accessing config' unless owner
        cfg = Rails::Plugin::Config.find_or_initialize_by(site_id: owner.id, name: name)
        cfg.options ||= default_options.dup
        cfg
      end
    end

    def default_options
      { 'string' => 'default string', 'text' => 'default text' }
    end

    # Persist and read options via method_missing
    def method_missing(meth, *args, &block)
      key = meth.to_s
      if key.end_with?('=')
        key = key.chomp('=')
        config.options[key] = args.first
      else
        (config.options || default_options)[key]
      end
    end

    def respond_to_missing?(meth, include_all = false)
      true
    end

    class Config < ActiveRecord::Base
      self.table_name = 'plugin_configs'
      serialize :options, coder: YAML
      belongs_to :site
    end
  end
end
