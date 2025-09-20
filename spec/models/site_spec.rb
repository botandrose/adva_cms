require "rails_helper"

RSpec.describe Site, type: :model do
  it "validates presence of host, name, title" do
    s = Site.new
    expect(s).not_to be_valid
    s.host = 'h'
    s.name = 'n'
    s.title = 't'
    expect(s).to be_valid
  end
end

