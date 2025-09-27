require "rails_helper"

RSpec.describe ContentHelper, type: :helper do
  include ContentHelper

  let(:site) { Site.create!(name: 'n', title: 't', host: 'helper.local') }
  let(:section) { Page.create!(site: site, title: 'p', permalink: 'p') }
  let(:user) { User.create!(first_name: 'U', email: 'u@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

  it "page_link_path returns link.body" do
    link = Link.create!(site: site, section: section, title: 'L', body: 'http://example.com', author: user, published_at: 1.hour.ago, permalink: 'l')
    expect(page_link_path(section, link)).to eq('http://example.com')
  end

  it "published_at_formatted returns Draft when not published and no future date" do
    a = Article.create!(site: site, section: section, title: 'D', body: 'b', author: user, published_at: nil, permalink: 'd')
    expect(published_at_formatted(a)).to eq('Draft')
  end

  it "published_at_formatted returns Will publish on when scheduled in future" do
    a = Article.create!(site: site, section: section, title: 'F', body: 'b', author: user, published_at: 1.day.from_now, permalink: 'f')
    expect(published_at_formatted(a)).to start_with('Will publish on ')
  end

  it "published_at_formatted localizes past published date" do
    a = Article.create!(site: site, section: section, title: 'P', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'p1')
    expect(published_at_formatted(a)).to be_a(String)
    expect(published_at_formatted(a)).not_to be_empty
  end

  it "published_at_formatted uses long format when different year" do
    a = Article.create!(site: site, section: section, title: 'Y', body: 'b', author: user, published_at: Time.zone.local(Time.zone.now.year - 1, 1, 1), permalink: 'y1')
    expect(published_at_formatted(a)).to be_a(String)
    expect(published_at_formatted(a)).not_to be_empty
  end

  it "links_to_content_tags returns joined tag links when tags present" do
    a = Article.create!(site: site, section: section, title: 'T', body: 'b', author: user, published_at: 1.hour.ago, permalink: 't2')
    a.tag_list = 'ruby, rails'
    a.save!
    html = links_to_content_tags(a)
    expect(html).to include('tagged: ')
    expect(html).to include('ruby')
    expect(html).to include('rails')
  end

  it "links_to_content_categories returns joined category links when present" do
    a = Article.create!(site: site, section: section, title: 'CT', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'ct')
    c1 = Category.create!(section: section, title: 'Cat1')
    c2 = Category.create!(section: section, title: 'Cat2')
    a.categories << [c1, c2]
    html = links_to_content_categories(a)
    expect(html).to include('in: ')
    expect(html).to include('Cat1')
    expect(html).to include('Cat2')
  end
end
