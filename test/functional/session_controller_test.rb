require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class SessionControllerTest < ActionController::TestCase
  tests SessionController

  setup do
    @site = Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com')
    @request.host = @site.host
  end

  test "renders login form" do
    get :new
    assert_response :success
    assert_includes @response.body, '<form'
    assert_includes @response.body, 'name="user[email]"'
  end

  test "unsuccessful login renders new with alert" do
    post :create, params: { user: { email: 'nobody@example.com', password: 'wrong' } }
    assert_response :success
    assert_includes @response.body, 'value="nobody@example.com"'
  end

  test "successful login redirects to return_to" do
    user = User.find_by_email('a-user@example.com') || User.create!(first_name: 'a user', email: 'a-user@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
    post :create, params: { user: { email: user.email, password: 'AAbbcc1122!!' } , return_to: '/' }
    assert_redirected_to '/'
  end
end
