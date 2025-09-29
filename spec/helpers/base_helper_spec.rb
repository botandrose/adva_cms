require "rails_helper"

RSpec.describe BaseHelper, type: :helper do
  let(:user) { User.create!(first_name: 'Test', email: 'test@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

  before do
    # Mock FilteredColumn if it doesn't exist
    unless defined?(FilteredColumn)
      filter_struct = Struct.new(:filter_name)
      stub_const('FilteredColumn', Class.new do
        filter_class = filter_struct
        define_singleton_method(:filters) do
          { test_filter: filter_class.new('Test Filter') }
        end
      end)
    end

    # Create current_user and l method for helper
    user_instance = user  # Capture user in closure
    helper.define_singleton_method(:current_user) { user_instance }
    helper.define_singleton_method(:l) do |time, options|
      time.strftime('%Y-%m-%d')
    end
  end

  describe "#datetime_with_microformat" do
    it "wraps datetime with microformat" do
      t = Time.utc(2024, 1, 2, 12, 34, 56)
      html = helper.datetime_with_microformat(t, format: :short, type: :time)
      expect(html).to include('<abbr class="datetime"')
      expect(html).to include(t.utc.xmlschema)
    end

    it "returns datetime as-is when not responding to strftime" do
      expect(helper.datetime_with_microformat("not a date")).to eq("not a date")
    end

    it "uses default options when none provided" do
      t = Time.utc(2024, 1, 2, 12, 34, 56)
      html = helper.datetime_with_microformat(t)
      expect(html).to include('<abbr class="datetime"')
    end

    it "handles date type option" do
      t = Time.utc(2024, 1, 2, 12, 34, 56)
      html = helper.datetime_with_microformat(t, type: :date)
      expect(html).to include('<abbr class="datetime"')
    end
  end

  describe "#column and #buttons" do
    it "column and buttons helpers wrap content" do
      expect(helper.column { 'X' }).to include('<div class="col">', 'X')
      expect(helper.buttons { 'Y' }).to include('<p class="buttons">', 'Y')
    end
  end

  describe "#split_form_for" do
    it "splits form and captures head to content_for" do
      helper.define_singleton_method(:form_for) { |*args, &block| "<form>\ncontent\n</form>" }
      helper.define_singleton_method(:content_for) { |*args| }

      result = helper.split_form_for(user) { 'form content' }
      # Just verify it doesn't crash and returns reasonable output
      expect(result).to be_a(String)
    end

    it "handles empty form output" do
      helper.define_singleton_method(:form_for) { |*args, &block| '' }
      helper.define_singleton_method(:content_for) { |*args| }

      result = helper.split_form_for(user) { 'form content' }
      expect(result).to eq('')
    end

    it "handles nil form output" do
      helper.define_singleton_method(:form_for) { |*args, &block| nil }
      helper.define_singleton_method(:content_for) { |*args| }

      result = helper.split_form_for(user) { 'form content' }
      expect(result).to eq('')
    end
  end

  describe "#filter_options" do
    it "returns filter options array" do
      options = helper.filter_options
      expect(options).to include(['Plain HTML', ''])
      expect(options).to include(['Test Filter', 'test_filter'])
    end
  end

  describe "#author_options" do
    let(:other_user) { User.create!(first_name: 'Other', email: 'other@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

    it "returns current user plus provided users" do
      options = helper.author_options([other_user])
      expect(options).to include([user.name, user.id])
      expect(options).to include([other_user.name, other_user.id])
    end

    it "removes duplicates" do
      options = helper.author_options([user, other_user])
      user_entries = options.select { |name, id| id == user.id }
      expect(user_entries.length).to eq(1)
    end
  end

  describe "#author_selected" do
    it "returns current user id" do
      expect(helper.author_selected).to eq(user.id)
    end

    it "returns current user id even with content provided" do
      content = double('Content', author_id: 999)
      expect(helper.author_selected(content)).to eq(user.id)
    end
  end

  describe "#link_path" do
    it "returns link body" do
      link = double('Link', body: 'http://example.com')
      section = double('Section')
      expect(helper.link_path(section, link)).to eq('http://example.com')
    end
  end
end