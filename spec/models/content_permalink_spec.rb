require "rails_helper"

RSpec.describe "Content permalink behavior", type: :model do
  let(:site) { Site.create!(name: 'n', title: 't', host: 'perma.local') }
  let(:section) { Page.create!(site: site, title: 'p', permalink: 'p') }
  let(:user) { User.create!(first_name: 'Bob', email: 'bob@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

  it "generates slug from title when permalink blank" do
    a = Article.create!(site: site, section: section, title: 'Hello Permalink!', body: 'b', author: user)
    expect(a.permalink).to eq('hello-permalink')
  end

  it "parameterizes permalink assignment" do
    a = Article.create!(site: site, section: section, title: 'x', body: 'b', author: user, permalink: 'Weird Slug')
    expect(a.permalink).to eq('weird-slug')
  end

  it "does not change slug when title changes later" do
    a = Article.create!(site: site, section: section, title: 'Original', body: 'b', author: user)
    original_slug = a.permalink
    a.update!(title: 'Changed Title')
    expect(a.reload.permalink).to eq(original_slug)
  end
end
