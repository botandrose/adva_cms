$: << File.dirname(__FILE__) + "/../lib"

require 'rubygems'
require 'active_support'
require 'action_pack'
require 'action_controller'
require 'action_view'
require 'action_view/test_case'
require 'tags'
require 'menu'

require 'test/unit'

class Test::Unit::TestCase
  begin
    include ActionController::Assertions::SelectorAssertions
  rescue NameError
    # ActionController::Assertions might not be available in newer Rails versions
  end

  def assert_html(html, *args, &block)
    # Simple HTML assertion for testing
    if html.include?(args.first.to_s)
      assert true
    else
      assert false, "Expected HTML to contain '#{args.first}', but got: #{html}"
    end
  end
end
