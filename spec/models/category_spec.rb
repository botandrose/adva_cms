require "rails_helper"

RSpec.describe Category, type: :model do
  let(:site) { Site.create!(name: 'n', title: 't', host: 'h.local') }
  let(:section) { Page.create!(site: site, title: 'a', permalink: 'a') }

  it "generates unique permalink when title duplicates within a section" do
    c1 = Category.create!(section: section, title: 'c')
    c2 = Category.create!(section: section, title: 'c')
    expect(c1.permalink).not_to eq(c2.permalink)
  end
end
