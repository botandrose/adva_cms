require "rails_helper"

RSpec.describe BaseHelper, type: :helper do
  include BaseHelper

  it "wraps datetime with microformat" do
    t = Time.utc(2024, 1, 2, 12, 34, 56)
    html = datetime_with_microformat(t, format: :short, type: :time)
    expect(html).to include('<abbr class="datetime"')
    expect(html).to include(t.utc.xmlschema)
  end

  it "column and buttons helpers wrap content" do
    expect(column { 'X' }).to include('<div class="col">', 'X')
    expect(buttons { 'Y' }).to include('<p class="buttons">', 'Y')
  end

  it "link_path returns link body" do
    link = double('Link', body: 'http://example.com')
    section = double('Section')
    expect(link_path(section, link)).to eq('http://example.com')
  end
end
