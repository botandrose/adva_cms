require 'spec_helper'

module TagsTests
  RSpec.describe 'Tag' do
    it 'uses the class name when no tag_name has been defined on subclass' do
      expect(Tags::Span.new.tag_name).to eq(:span)
    end

    it 'can render an empty tag' do
      assert_html Tags::Span.new.render, 'span'
    end
  end
end