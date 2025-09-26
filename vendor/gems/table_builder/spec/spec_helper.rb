require 'rspec'

# Add the lib directory to the load path
$: << File.expand_path('../../lib', __FILE__)

# Load dependencies in correct order
require 'active_support/all'
require 'action_view/helpers/tag_helper'
require 'action_view/base'
require 'i18n'

# Load table_builder
require 'table_builder'

# Configure I18n for testing
I18n.backend = I18n::Backend::KeyValue.new({})

RSpec.configure do |config|
  config.before(:each) do
    # Reset table builder options
    TableBuilder.options[:i18n_scope] = nil
  end
end

# Helper methods for table building
module TableTestHelper
  def build_table(*columns)
    columns = [build_column('foo'), build_column('bar')] if columns.empty?
    Table.new(nil, %w(foo bar)) do |table|
      columns.each { |column| table.column(column.name, column.options) }
    end
  end

  def build_column(name, options = {})
    OpenStruct.new(:name => name, :options => options)
  end

  def build_body_row
    body = build_table.body
    body.send(:new_row)
  end
end

# Custom HTML assertion helper using Nokogiri
def assert_html(html, selector, expected_content = nil, &block)
  doc = Nokogiri::HTML::DocumentFragment.parse(html)
  elements = doc.css(selector)

  expect(elements).not_to be_empty, "Expected to find elements matching '#{selector}' in:\n#{html}"

  if expected_content
    content_found = elements.any? { |el| el.text.strip == expected_content.to_s }
    expect(content_found).to be(true), "Expected to find content '#{expected_content}' in elements matching '#{selector}'"
  end

  if block_given?
    # For nested assertions, we need to create a context
    nested_context = Object.new
    nested_context.define_singleton_method(:assert_select) do |nested_selector, nested_content = nil|
      nested_elements = doc.css(nested_selector)
      expect(nested_elements).not_to be_empty, "Expected to find elements matching '#{nested_selector}'"

      if nested_content
        nested_content_found = nested_elements.any? { |el| el.text.strip == nested_content.to_s }
        expect(nested_content_found).to be(true), "Expected to find content '#{nested_content}' in elements matching '#{nested_selector}'"
      end
    end

    nested_context.instance_eval(&block)
  end
end

# Load OpenStruct for column building
require 'ostruct'

# Load Nokogiri for HTML parsing
require 'nokogiri'