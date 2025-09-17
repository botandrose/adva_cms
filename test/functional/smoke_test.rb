require File.expand_path("../test_helper", __dir__)

class ArticlesControllerSmokeTest < ActionController::TestCase
  tests ArticlesController

  def setup
    super
    @request.host = 'smoke.local'
    # create minimal data
    @site = Site.create!(name: 'smoke', title: 'smoke', host: @request.host)
    @page = Page.create!(site: @site, title: 'a page', permalink: 'a-page', comment_age: 0, published_at: Time.now)
    @user = User.create!(first_name: 'a user', email: 'user@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
    @article = Article.create!(site: @site, section: @page, title: 'hello world', body: 'body', author: @user, published_at: Time.now)
  end

  test "article show responds" do
    def @controller.render(*args); head :ok; end
    get :show, params: { section_permalink: @page.permalink, permalink: @article.permalink }
    assert_response :success
  end
end
