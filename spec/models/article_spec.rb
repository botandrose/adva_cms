require "rails_helper"

RSpec.describe Article, type: :model do
  let(:site) { Site.create!(name: 'basic', title: 'basic', host: 'basic.local') }
  let(:page) { Page.create!(site: site, title: 'page', permalink: 'page') }
  let(:user) { User.create!(first_name: 'user', email: 'user@ex.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

  it "validates presence of title and body" do
    a = Article.new(site: site, section: page, author: user)
    expect(a).not_to be_valid
    a.title = 'Hello'
    a.body = 'World'
    expect(a).to be_valid
  end
end

