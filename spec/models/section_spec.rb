require "rails_helper"

RSpec.describe Section, type: :model do
  let(:site) { Site.create!(name: 'n', title: 't', host: 'h.local') }

  it "validates presence of title and uniqueness of permalink scoped to site" do
    s1 = Page.create!(site: site, title: 'a', permalink: 'a')
    s2 = Page.new(site: site, title: 'b', permalink: 'a')
    expect(s2).not_to be_valid
  end

  it "to_param returns permalink" do
    s = Page.create!(site: site, title: 'a', permalink: 'a')
    expect(s.to_param).to eq('a')
  end
end

