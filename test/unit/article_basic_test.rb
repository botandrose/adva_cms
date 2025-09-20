require File.expand_path("../test_helper", __dir__)

class ArticleBasicTest < ActiveSupport::TestCase
  def setup
    super
    @site = Site.create!(name: 'basic', title: 'basic', host: 'basic.local')
    @page = Page.create!(site: @site, title: 'page', permalink: 'page')
    @user = User.create!(first_name: 'user', email: 'user@ex.com', password: 'AAbbcc1122!!', verified_at: Time.now)
  end

  test "validates presence of title and body" do
    a = Article.new(site: @site, section: @page, author: @user)
    assert_not a.valid?
    a.title = 'Hello'
    a.body = 'World'
    assert a.valid?
  end
end
