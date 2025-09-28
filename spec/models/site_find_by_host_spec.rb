require "rails_helper"

RSpec.describe Site, type: :model do
  after { Site.multi_sites_enabled = nil }

  it "find_by_host! returns the only site when multi-sites disabled" do
    Site.multi_sites_enabled = false
    Site.delete_all
    s = Site.create!(name: 'Solo', title: 'Solo', host: 'UPPER.Host')
    expect(Site.find_by_host!('anything.local')).to eq(s)
  end

  it "find_by_host! finds by exact host when multi-sites enabled" do
    Site.multi_sites_enabled = true
    a = Site.create!(name: 'A', title: 'A', host: 'a.local')
    b = Site.create!(name: 'B', title: 'B', host: 'b.local')
    expect(Site.find_by_host!('b.local')).to eq(b)
    expect { Site.find_by_host!('c.local') }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "normalizes host on validation (downcase and strip spaces)" do
    s = Site.create!(name: 'N', title: 'T', host: '  MiXeD Case .LOCAL  ')
    expect(s.host).to eq('mixed-case-.local')
  end

  it ".bust_cache! touches all sites" do
    s = Site.create!(name: 'N', title: 'T', host: 'touch.local')
    before = s.updated_at
    Site.bust_cache!
    expect(s.reload.updated_at).not_to eq(before)
  end
end
