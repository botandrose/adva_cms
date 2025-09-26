$: << File.dirname(__FILE__) + "/../lib"

require 'rubygems'
require 'test/unit'
require 'active_support'
require 'action_pack'
require 'action_controller'
require 'action_view'
require 'action_view/test_case'
require 'table_builder'
require 'nokogiri'

class Test::Unit::TestCase
  begin
    include ActionController::Assertions::SelectorAssertions
  rescue NameError
    # ActionController::Assertions might not be available in newer Rails versions
  end

  def assert_html(html, *args, &block)
    selector = args.first.to_s
    expected_text = args[1].to_s if args[1]

    # Parse HTML with Nokogiri
    doc = Nokogiri::HTML::DocumentFragment.parse(html)

    # If we have a CSS selector, use Nokogiri to find elements
    unless selector.empty?
      elements = doc.css(selector)
      assert !elements.empty?, "Expected HTML to contain elements matching '#{selector}', but got: #{html}"

      # If expected text is provided, check that at least one element contains it
      if expected_text && !expected_text.empty?
        found_text = elements.any? { |element| element.text.include?(expected_text) }
        assert found_text, "Expected elements matching '#{selector}' to contain text '#{expected_text}', but got: #{html}"
      end
    end

    # If expected text is provided but no selector, just check the text is somewhere in the HTML
    if expected_text && !expected_text.empty? && selector.empty?
      assert html.include?(expected_text), "Expected HTML to contain text '#{expected_text}', but got: #{html}"
    end
  end
end

module TableBuilder
  module TableTestHelper
    def setup
      @scope = TableBuilder.options[:i18n_scope]
    end
  
    def teardown
      TableBuilder.options[:i18n_scope] = @scope
    end
    
    def build_column(name, options = {})
      Column.new(nil, name, options)
    end
  
    def build_table(*columns)
      columns = [build_column('foo'), build_column('bar')] if columns.empty?
      table = Table.new(nil, %w(foo bar))
      table.instance_variable_set(:@columns, columns)
      columns.each { |column| column.instance_variable_set(:@table, table) }
      table
    end
    
    def build_body(*columns)
      Body.new(build_table(*columns))
    end
    
    def build_body_row(*columns)
      Row.new(build_body(*columns))
    end
  end
end