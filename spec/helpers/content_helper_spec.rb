require "rails_helper"

RSpec.describe ContentHelper, type: :helper do
  include ContentHelper

  ContentDummy = Struct.new(:pub) do
    def published?; pub; end
  end

  it "returns status span text based on published flag" do
    expect(content_status(ContentDummy.new(true))).to include('Published')
    expect(content_status(ContentDummy.new(false))).to include('Pending')
  end
end
