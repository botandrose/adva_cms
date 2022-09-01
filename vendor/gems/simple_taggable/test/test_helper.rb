require 'test/unit'

require 'active_support'
require 'active_support/test_case'
require 'active_support/testing/autorun'
require 'active_record'
require 'active_record/fixtures'

dir = File.dirname(__FILE__)
$: << File.expand_path(dir + '/../lib')
$: << File.expand_path(dir + '/fixtures')
ENV['RAILS_ENV'] = 'test'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

load File.expand_path(dir + '/db/schema.rb')

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures

  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = true
  self.fixture_path = File.dirname(__FILE__) + '/fixtures/'
  
  def assert_queries(num = 1)
    $query_count = 0
    yield
  ensure
    assert_equal num, $query_count, "#{$query_count} instead of #{num} queries were executed."
  end

  def assert_no_queries(&block)
    assert_queries(0, &block)
  end

  def assert_equivalent(expected, actual, message = nil)
    if expected.first.is_a?(ActiveRecord::Base)
      assert_equal expected.sort_by(&:id), actual.sort_by(&:id), message
    else
      assert_equal expected.sort, actual.sort, message
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
      
      assert_not_nil value, "Expected count for #{tag.name} was not provided"
      assert_equal value, tag.count, "Expected value of #{value} for #{tag.name}, but was #{tag.count}"
    end
    
    unless expected_values.empty?
      assert false, "The following tag counts were not present: #{expected_values.inspect}"
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
      assert_equal(before[i] + difference, e.call, error)
    end
  end
end

