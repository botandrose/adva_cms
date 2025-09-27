require 'rspec'
require 'active_support'
require 'active_support/core_ext/string'
require 'active_record'

dir = File.dirname(__FILE__)
$: << File.expand_path(dir + '/../lib')
ENV['RAILS_ENV'] = 'test'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

load File.expand_path(dir + '/support/schema.rb')

# Load simple_taggable which defines Tag and Tagging models
require 'simple_taggable'

require_relative 'support/models/magazine'
require_relative 'support/models/photo'
require_relative 'support/models/post'
require_relative 'support/models/subscription'
require_relative 'support/models/user'

RSpec.configure do |config|
  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end

# Custom matchers and helpers for simple_taggable
module SimpleTaggableSpecHelpers
  def assert_equivalent(expected, actual, message = nil)
    if expected.first.is_a?(ActiveRecord::Base)
      expect(actual.sort_by(&:id)).to eq(expected.sort_by(&:id)), message
    else
      expect(actual.sort).to eq(expected.sort), message
    end
  end

  def assert_tag_counts(tags, expected_values)
    expected_by_name = expected_values.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
    actual_by_name = tags.each_with_object({}) { |t, h| h[t.name] = t.count }
    expected_by_name.each do |name, count|
      expect(actual_by_name[name]).to eq(count), "Expected #{name} => #{count}, got #{actual_by_name[name].inspect}"
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
