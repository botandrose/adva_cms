require "rails_helper"

RSpec.describe ContentHelper, type: :helper do
  include ContentHelper

  let(:site) { Site.create!(name: 'n', title: 't', host: 'chk.local') }
  let(:section) { Page.create!(site: site, title: 'p', permalink: 'p') }
  let(:user) { User.create!(first_name: 'U', email: 'u4@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

  it "renders content_category_checkbox with checked state" do
    a = Article.create!(site: site, section: section, title: 'a', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'a')
    cat = Category.create!(section: section, title: 'C')
    a.categories << cat

    html = content_category_checkbox(a, cat)
    expect(html).to include("type=\"checkbox\"")
    expect(html).to include("checked=\"checked\"")
    expect(html).to include("article_category_#{cat.id}")
  end
end

