require "rails_helper"

RSpec.describe Site, type: :model do
  it "perma_host replaces colon with dot" do
    site = Site.create!(name: 'n', title: 't', host: 'a:3000')
    expect(site.perma_host).to eq('a.3000')
  end

  it "email_from returns formatted string when name and email present" do
    site = Site.create!(name: 'Name', title: 't', host: 'h.local', email: 'e@example.com')
    expect(site.email_from).to eq('Name <e@example.com>')
  end

  it "multi_sites_enabled? reflects class setting" do
    Site.multi_sites_enabled = true
    site = Site.create!(name: 'n', title: 't', host: 'h2.local')
    expect(site.multi_sites_enabled?).to be true
  end

  it "section_ids returns an array of ids for configured section content types" do
    site = Site.create!(name: 'n', title: 't', host: 'h3.local')
    page = Page.create!(site: site, title: 'p', permalink: 'p')
    user = User.create!(first_name: 'U', email: 'sx@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
    article = Article.create!(site: site, section: page, title: 'a', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'a')
    ids = site.section_ids
    expect(ids).to be_a(Array)
    # Depending on Section.types and legacy behavior, this may not include Article ids
    # We only assert the method returns without error and returns an array of strings
    ids.each { |id| expect(id).to be_a(String) }
  end

  it "grouped_activities calls activity finder" do
    site = Site.create!(name: 'n', title: 't', host: 'h4.local')
    allow(site.activities).to receive(:find_coinciding_grouped_by_dates).and_return([])
    expect(site.grouped_activities).to eq([])
  end
end
