require "rails_helper"

RSpec.describe Adva::BelongsToAuthor do
  let(:site) { Site.create!(name: 'n', title: 't', host: 'author.local') }
  let(:section) { Page.create!(site: site, title: 'p', permalink: 'p') }
  let(:user) { User.create!(first_name: 'Alice', email: 'alice@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

  it "exposes author_* helpers and builds a mailto link" do
    # Stub tracking attributes on the user instance
    allow(user).to receive(:ip).and_return('127.0.0.1')
    allow(user).to receive(:agent).and_return('RSpec')
    allow(user).to receive(:referer).and_return('http://ref')

    article = Article.create!(site: site, section: section, title: 't', body: 'b', author: user, published_at: 1.hour.ago, permalink: 't')

    expect(article.author_ip).to eq('127.0.0.1')
    expect(article.author_agent).to eq('RSpec')
    expect(article.author_referer).to eq('http://ref')

    expect(article.author_link).to include('mailto:alice@example.com')
    expect(article.author_link(include_email: false)).to include('Alice')
  end
end

