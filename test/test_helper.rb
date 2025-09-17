defined?(TEST_HELPER_LOADED) ? raise("can not load #{__FILE__} twice") : TEST_HELPER_LOADED = true

dir = File.dirname(__FILE__)

# Modern test boot: use internal dummy Rails app if present
internal_env = File.expand_path("internal/config/environment.rb", __dir__)
if File.exist?(internal_env)
  ENV["RAILS_ENV"] ||= "test"
  require internal_env
  require "rails/test_help"
  require "test/unit"
  begin
    require "rails-controller-testing"
  rescue LoadError
  end

  # Minimal common test configuration
  I18n.default_locale = :en
  I18n.locale = :en

  # Backwards compat: define missing test response constant early
  unless defined?(ActionController::TestResponse)
    module ActionController
      TestResponse = ActionDispatch::TestResponse
    end
  end

  # Load With DSL and sugar
  $LOAD_PATH.unshift File.expand_path("with/lib", __dir__)
  require "with"
  $LOAD_PATH.unshift File.expand_path("with-sugar/lib", __dir__)
  require "with-sugar/core"
  require "with-sugar/controller"
  require "with-sugar/view"
  require "with-sugar/model"
  require "with-sugar/routing"
  require "with-sugar/caching"
  # Also include With into ActiveSupport::TestCase so DSL is available
  ActiveSupport::TestCase.send :include, With

  # Load shared contexts
  require File.expand_path("contexts.rb", __dir__)
  require File.expand_path("adva_user_contexts.rb", __dir__)
  # Provide missing contexts used by older tests
  if defined?(Test::Unit::TestCase)
    Test::Unit::TestCase.class_eval do
      share :a_blog do
        before do
          @section = Section.find_by_permalink 'a-page'
          @site = @section.site
          set_request_host!
        end
      end
    end
  end

  # Load RR mocking adapter
  $LOAD_PATH.unshift File.expand_path("rr/lib", __dir__)
  require "rr/hash_with_object_id_key"
  require "rr/recorded_calls"
  require "rr/space"
  # Minimal delegators for vendored RR subset
  module RR
    class << self
      def space; RR::Space.instance; end
      def reset; space.reset; end
      def verify(*args); space.verify(*args); end
      def trim_backtrace=(v); space.trim_backtrace = v; end
      def trim_backtrace; space.trim_backtrace; end
    end
  end
  require "rr/adapters/rr_methods"
  require "rr/adapters/test_unit"
  ActiveSupport::TestCase.include RR::Adapters::TestUnit

  # Load vendored testing helpers and DSLs (after With & RR)
  helper_dir = File.expand_path("test_helper", __dir__)
  Dir[File.join(helper_dir, "**", "*.rb")]
    .reject { |f|
      f.end_with?("/test_unit.rb") ||
      f.end_with?("/extensions/rails_patch.rb") ||
      f.end_with?("/setup_webrat.rb") ||
      f.include?("/test_server/")
    }
    .sort.each { |f| require f }


  # Enable assigns/assert_template for Rails >= 5
  begin
    if defined?(Rails::Controller::Testing::TemplateAssertions)
      [ActionDispatch::IntegrationTest, ActionController::TestCase, ActionView::TestCase].each do |klass|
        klass.include Rails::Controller::Testing::TemplateAssertions
        klass.include Rails::Controller::Testing::ControllerAssertions
        klass.include Rails::Controller::Testing::Integration
      end
    end
  rescue NameError
  end

  # Basic per-test setup matching legacy helpers
  class ActiveSupport::TestCase
    setup do
      I18n.default_locale = :en
      I18n.locale = :en
      if ActionController::Base.respond_to?(:page_cache_directory=)
        ActionController::Base.page_cache_directory = Rails.root.join('tmp', 'cache').to_s
        ActionController::Base.perform_caching = true
      end
      @old_multi_sites_enabled = Site.multi_sites_enabled
      Site.multi_sites_enabled = false
    end

    teardown do
      if ActionController::Base.respond_to?(:page_cache_directory)
        cache_dir = ActionController::Base.page_cache_directory
        FileUtils.rm_r(cache_dir) if cache_dir && File.exist?(cache_dir)
      end
      Site.multi_sites_enabled = @old_multi_sites_enabled
    end
  end

else
  # Legacy boot (kept for backwards compatibility if internal app is absent)
  def rails_root
    d = File.expand_path(File.dirname(__FILE__) + "/../..")
    while d = File.dirname(d) and d != '/' do
      return d if File.exists?("#{d}/config/environment.rb")
    end
  end

  ENV["RAILS_ENV"] = "test"
  require "#{rails_root}/config/environment.rb"

  require 'matchy'
  require 'test_help'
  require 'action_view/test_case'
  require 'with'
  require 'with-sugar'

  require 'globalize/i18n/missing_translations_raise_handler'
  I18n.exception_handler = :missing_translations_raise_handler

  class ActiveSupport::TestCase
    include RR::Adapters::TestUnit

    setup :start_db_transaction!
    setup :setup_page_caching!
    setup :set_locale!
    setup :ensure_single_site_mode!

    teardown :rollback_db_transaction!
    teardown :clear_cache_dir!
    teardown :rollback_multi_site_mode!
    
    setup do
      @default_permissions = Rbac::Context.default_permissions.dup
    end

    teardown do
      Rbac::Context.default_permissions = @default_permissions
    end
    
    
    def set_locale!
      I18n.locale = nil
      I18n.default_locale = :en
    end

    def stub_paperclip_post_processing!
      stub.proxy(Paperclip::Attachment).new { |attachment| stub(attachment).post_process }
    end
  end

  # include this line to test adva-cms with url_history installed
  # require dir + '/plugins/url_history/init_url_history'

  # reset locales in case client apps set them in the environment
  I18n.default_locale = :en
  I18n.locale = nil

  require_all dir + "/contexts.rb",
              dir + "/test_helper/**/*.rb"
  require_all dir + "/../../*/test/contexts.rb",
              dir + "/../../*/test/test_helper/**/*.rb"

  if DO_PREPARE_DATABASE
    puts 'Preparing the database ...'
    # load "#{Rails.root}/db/schema.rb"
    require_all dir + "/fixtures.rb"
    require_all dir + "/../../*/test/fixtures.rb"
    
    ActiveSupport::TestCase.setup :clear_tmp_dir!
  end

  require "#{Rails.root}/test/test_helper.rb" if File.exists?("#{Rails.root}/test/test_helper.rb")
end
