require "rails_helper"

RSpec.describe Adva::HasOptions do
  describe "option_definition rescue to superclass" do
    it "looks up missing option on superclass via rescue (class ancestry)" do
      # Section defines :contents_per_page with default 15 via has_option
      # Page < Section inherits, but we clear its option_definitions to force fallback
      original = Page.option_definitions
      begin
        Page.option_definitions = {}
        expect(Page.option_definition(:contents_per_page, :default)).to eq(15)
      ensure
        Page.option_definitions = original
      end
    end
  end
end

