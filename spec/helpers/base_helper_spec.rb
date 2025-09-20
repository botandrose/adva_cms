require "rails_helper"

RSpec.describe BaseHelper, type: :helper do
  include BaseHelper

  it "wraps datetime with microformat" do
    t = Time.utc(2024, 1, 2, 12, 34, 56)
    html = datetime_with_microformat(t, format: :short, type: :time)
    expect(html).to include('<abbr class="datetime"')
    expect(html).to include(t.utc.xmlschema)
  end
end

