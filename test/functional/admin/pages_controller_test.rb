require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class AdminPagesControllerTest < ActionController::TestCase
  tests Admin::PagesController

  test "is an Admin::SectionsController" do
    assert_kind_of Admin::SectionsController, @controller
  end

  test "anonymous user redirected to login for index" do
    site = Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com')
    @request.host = site.host
    get :index
    assert_redirected_to login_url(return_to: admin_pages_url)
  end
end
