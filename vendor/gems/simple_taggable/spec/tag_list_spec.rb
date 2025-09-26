require 'spec_helper'
require 'tag_list'

RSpec.describe TagList do
  after(:each) do
    TagList.delimiter = ' '
  end

  describe "#from" do
    it "leaves arguments unchanged" do
      tags = '"One  ", Two'
      original = tags.dup
      TagList.from(tags)
      expect(tags).to eq(original)
    end

    it "handles a single tag name" do
      expect(TagList.from("Fun")).to eq(%w(Fun))
    end

    it "handles a single quoted tag name" do
      expect(TagList.from("'Fun'")).to eq(%w('Fun'))
    end

    it "handles a double quoted tag name" do
      expect(TagList.from('"Fun"')).to eq(%w(Fun))
    end

    it "handles a single blank tag name" do
      expect(TagList.from(nil)).to eq([])
      expect(TagList.from("")).to eq([])
    end

    it "handles tags contained in quoted tags" do
      expect(TagList.from('"foo bar" bar')).to eq(['foo bar', 'bar'])
    end

    it "handles a single quoted tag name that includes a comma (with comma delimiter)" do
      TagList.delimiter = ','
      expect(TagList.from("'with, comma'")).to eq(["'with, comma'"])
    end

    it "handles a double quoted tag name that includes a comma (with comma delimiter)" do
      TagList.delimiter = ','
      expect(TagList.from('"with, comma"')).to eq(['with, comma'])
    end

    it "does not delineate spaces (with comma delimiter)" do
      TagList.delimiter = ','
      expect(TagList.from('foo bar, baz')).to eq(['foo bar', 'baz'])
    end

    it "handles multiple tags" do
      expect(TagList.from("One Two")).to eq(%w(One Two))
    end

    it "handles multiple tags with quotes and multiple spaces" do
      expect(TagList.from('"One  " Two')).to eq(['One  ', 'Two'])
    end

    it "handles multiple tags with single quotes" do
      expect(TagList.from("'One  ' Two")).to eq(["'One  '", 'Two'])
    end

    it "handles multiple tags with double quotes" do
      expect(TagList.from('"One  " "Two"')).to eq(['One  ', 'Two'])
    end

    it "handles multiple tags with quotes and commas (with comma delimiter)" do
      TagList.delimiter = ','
      expect(TagList.from('"One  ", Two')).to eq(['One  ', 'Two'])
    end

    it "removes leading/trailing whitespace from tag names" do
      expect(TagList.from("' One  ', ' Two '")).to eq(['One  ', 'Two'])
    end

    it "removes duplicate tags" do
      expect(TagList.from("One Two One")).to eq(['One', 'Two'])
    end
  end

  describe "#to_s" do
    it "works with comma delimiter" do
      TagList.delimiter = ','
      list = TagList.new
      list.add("One")
      list.add("Two")
      expect(list.to_s).to eq("One, Two")
    end

    it "works with space delimiter" do
      list = TagList.new
      list.add("One")
      list.add("Two")
      expect(list.to_s).to eq("One Two")
    end
  end

  describe "#add" do
    it "adds tags" do
      list = TagList.new
      list.add("Name")
      expect(list.include?("Name")).to be(true)
    end
  end

  describe "#remove" do
    it "removes tags" do
      list = TagList.new
      list.add("Name")
      list.remove("Name")
      expect(list.include?("Name")).to be(false)
    end
  end

  describe "initialization and parsing" do
    it "handles new with parsing" do
      list = TagList.new("One, Two")
      expect(list.include?("One")).to be(true)
      expect(list.include?("Two")).to be(true)
    end

    it "handles add with parsing" do
      list = TagList.new
      list.add("One, Two")
      expect(list.include?("One")).to be(true)
      expect(list.include?("Two")).to be(true)
    end

    it "handles remove with parsing" do
      list = TagList.new("One, Two, Three")
      list.remove("One, Two")
      expect(list.include?("One")).to be(false)
      expect(list.include?("Two")).to be(false)
      expect(list.include?("Three")).to be(true)
    end
  end

  describe "#cover_pluralities!" do
    it "covers pluralities" do
      list = TagList.new("ruby, rails")
      list.cover_pluralities!
      expect(list.include?("ruby")).to be(true)
      expect(list.include?("rubies")).to be(true)
      expect(list.include?("rails")).to be(true)
    end
  end
end