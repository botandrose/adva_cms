require "rails_helper"

RSpec.describe BaseController do
  it "skip_caching? reflects draft content and skip_caching! flag" do
    controller = BaseController.new

    site = Site.create!(name: 'n', title: 't', host: 'cache.local')
    section = Page.create!(site: site, title: 'p', permalink: 'p')
    user = User.create!(first_name: 'Admin', email: 'admin@example.com', password: 'AAbbcc1122!!', verified_at: Time.now, admin: true)

    draft = Article.create!(site: site, section: section, title: 'd', body: 'b', author: user, published_at: nil, permalink: 'd')
    controller.instance_variable_set(:@article, draft)
    expect(controller.send(:skip_caching?)).to be_truthy

    controller.instance_variable_set(:@article, nil)
    expect(controller.send(:skip_caching?)).to be_falsey
    controller.send(:skip_caching!)
    expect(controller.send(:skip_caching?)).to be_truthy
  end
end
