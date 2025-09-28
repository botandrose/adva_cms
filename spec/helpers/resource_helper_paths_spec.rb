require "rails_helper"

RSpec.describe ResourceHelper, type: :helper do
  include ResourceHelper

  it "raises when resource is new" do
    expect { resource_url(:show, Site.new) }.to raise_error(/can not generate a url/)
  end

  it "calls dynamic *_url and *_path helpers" do
    site = Site.create!(name: 'n', title: 't', host: 'paths.local')
    section = Page.create!(site: site, title: 'p', permalink: 'p')
    user = User.create!(first_name: 'U', email: 'u4@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
    article = Article.create!(site: site, section: section, title: 'a', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'ax')

    # show_url (absolute) and edit_path (relative) exercise dynamic methods
    allow(helper).to receive(:resource_url).and_return('/x')
    expect(helper.show_url(article)).to eq('/x')
    expect(helper.edit_path(article)).to eq('/x')
  end
end
