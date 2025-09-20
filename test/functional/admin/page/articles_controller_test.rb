require File.expand_path(File.dirname(__FILE__) + "/../../../test_helper")

class AdminPageArticlesControllerTest < ActionController::TestCase
  tests Admin::Page::ArticlesController

  test "is an Admin::BaseController" do
    assert_kind_of Admin::BaseController, @controller
  end

  test "anonymous user redirected to login for index" do
    section = Section.find_by_permalink('a-page') || Section.first
    skip "no section available" unless section
    site = section.site
    @request.host = site.host
    get :index, params: { page_id: section.permalink }
    assert_redirected_to login_url(return_to: admin_page_articles_url(section))
  end
end

