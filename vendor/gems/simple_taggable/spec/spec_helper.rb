require 'rspec'
require 'yaml'
require 'active_support'
require 'active_support/core_ext/string'
require 'active_record'

dir = File.dirname(__FILE__)
$: << File.expand_path(dir + '/../lib')
$: << File.expand_path(dir + '/../test/fixtures')
ENV['RAILS_ENV'] = 'test'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

load File.expand_path(dir + '/../test/db/schema.rb')

# Load simple_taggable which defines Tag and Tagging models
require 'simple_taggable'

# Load test models
require 'magazine'
require 'photo'
require 'post'
require 'subscription'
require 'user'

# Manual fixture loading
def load_fixtures
  fixture_path = File.dirname(__FILE__) + '/../test/fixtures/'

  # Load YML fixtures
  fixtures_data = {}
  ['tags', 'taggings', 'photos', 'posts', 'subscriptions', 'magazines', 'users'].each do |fixture_name|
    file_path = File.join(fixture_path, "#{fixture_name}.yml")
    if File.exist?(file_path)
      fixtures_data[fixture_name] = YAML.load_file(file_path)
    end
  end

  # Create instance variables for each fixture
  fixtures_data.each do |table_name, records|
    records.each do |name, attributes|
      model_class = table_name.classify.constantize
      record = model_class.create!(attributes)
      instance_variable_set("@#{name}", record)
    end
  end
end

RSpec.configure do |config|
  config.before(:each) do |example|
    # Only load fixtures for tests that need them (not tag_list_spec)
    unless example.metadata[:file_path].include?('tag_list_spec')
      load_fixtures
    end
  end

  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end

# Custom matchers and helpers for simple_taggable
module SimpleTaggableSpecHelpers
  def assert_queries(num = 1)
    $query_count = 0
    yield
  ensure
    expect($query_count).to eq(num), "#{$query_count} instead of #{num} queries were executed."
  end

  def assert_no_queries(&block)
    assert_queries(0, &block)
  end

  def assert_equivalent(expected, actual, message = nil)
    if expected.first.is_a?(ActiveRecord::Base)
      expect(actual.sort_by(&:id)).to eq(expected.sort_by(&:id)), message
    else
      expect(actual.sort).to eq(expected.sort), message
    end
  end

  def assert_tag_counts(tags, expected_values)
    # Map the tag fixture names to real tag names
    expected_values = expected_values.inject({}) do |hash, (tag, count)|
      hash[tags(tag).name] = count
      hash
    end

    tags.each do |tag|
      value = expected_values.delete(tag.name)

      expect(value).not_to be_nil, "Expected count for #{tag.name} was not provided"
      expect(tag.count).to eq(value), "Expected value of #{value} for #{tag.name}, but was #{tag.count}"
    end

    unless expected_values.empty?
      fail "The following tag counts were not present: #{expected_values.inspect}"
    end
  end

  def assert_difference(expression, difference = 1, message = nil, &block)
    expressions = Array(expression)

    exps = expressions.map { |e|
      e.respond_to?(:call) ? e : lambda { eval(e, block.binding) }
    }
    before = exps.map { |e| e.call }

    yield

    expressions.zip(exps).each_with_index do |(code, e), i|
      error  = "#{code.inspect} didn't change by #{difference}"
      error  = "#{message}.\n#{error}" if message
      expect(e.call).to eq(before[i] + difference), error
    end
  end
end

RSpec.configure do |config|
  config.include SimpleTaggableSpecHelpers
end