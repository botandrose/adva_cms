require "rails_helper"

RSpec.describe ResourceHelper, type: :helper do
  include ResourceHelper

  it "links_to_actions concatenates resource links" do
    allow(self).to receive(:resource_link).and_return('<a>Edit</a>', '<a>Delete</a>')
    html = links_to_actions([:edit, :delete], :resource)
    expect(html).to include('Edit')
    expect(html).to include('Delete')
  end
end

