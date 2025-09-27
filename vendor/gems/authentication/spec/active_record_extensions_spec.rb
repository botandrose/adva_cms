require 'spec_helper'

RSpec.describe 'ActiveRecord extensions' do
  class ColumnTest < ActiveRecord::Base
    def self.column_names
      %w(id name foo bar baz)
    end
  end

  it 'checks includes_all_columns? for present columns' do
    expect(ColumnTest.includes_all_columns?(:foo, :bar)).to be true
  end

  it 'checks includes_all_columns? for missing column' do
    expect(ColumnTest.includes_all_columns?(:foo, :boo)).to be false
  end
end

