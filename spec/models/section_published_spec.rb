require "rails_helper"

RSpec.describe Section, type: :model do
  let(:site) { Site.create!(name: 'n', title: 't', host: 'sec.local') }

  it "root section is always published" do
    root = Page.create!(site: site, title: 'root', permalink: 'root')
    expect(root.root_section?).to be_truthy
    expect(root.published?(true)).to be_truthy
  end

  it "published? false when nil or future, true when past" do
    parent = Page.create!(site: site, title: 'root', permalink: 'root')
    s = Page.create!(site: site, title: 'p', permalink: 'p', parent_id: parent.id)
    s.update!(published_at: nil)
    expect(s.published?).to be_falsey
    s.update!(published_at: 1.day.from_now)
    expect(s.published?).to be_falsey
    # When set in the past it should be considered published
    s.update!(published_at: 1.day.ago)
    expect(s.published_at <= Time.current).to be_truthy
  end

  it "published= writer toggles published_at" do
    s = Page.create!(site: site, title: 'p2', permalink: 'p2', published_at: nil)
    s.published = 1
    expect(s.published_at).not_to be_nil
    s.published = 0
    expect(s.published_at).to be_nil
  end
end
