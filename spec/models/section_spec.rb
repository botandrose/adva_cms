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

  it "parameterizes permalink on assignment" do
    s = Page.create!(site: site, title: 'Hello', permalink: 'Hello World!')
    expect(s.permalink).to eq('hello-world')
  end

  it "provides default option value via has_option" do
    s = Page.create!(site: site, title: 'opt', permalink: 'opt')
    expect(s.contents_per_page).to eq(15)
  end

  it "does not change permalink when title changes (friendly id only when blank)" do
    s = Page.create!(site: site, title: 'a', permalink: 'custom')
    s.update!(title: 'changed')
    expect(s.reload.permalink).to eq('custom')
  end
end
