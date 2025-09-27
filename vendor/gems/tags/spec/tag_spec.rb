require 'spec_helper'

module TagsTests
  RSpec.describe 'Tag' do
    it 'uses the class name when no tag_name has been defined on subclass' do
      expect(Tags::Span.new.tag_name).to eq(:span)
    end

    it 'can render an empty tag' do
      assert_html Tags::Span.new.render, 'span'
    end

    it 'titleizes symbol content' do
      assert_html Tags::Span.new(:hello_world).render, 'span', 'Hello World'
    end

    # Test the lf helper method (line 103)
    it 'lf method adds newlines' do
      tag = Tags::Span.new
      result = tag.send(:lf, 'test')
      expect(result).to eq("\ntest\n")
    end

    # Test the indent helper method (line 107)
    it 'indent method adds spaces to beginning of lines' do
      tag = Tags::Span.new
      result = tag.send(:indent, "line1\nline2")
      expect(result).to eq("  line1\n  line2")
    end
  end
end
