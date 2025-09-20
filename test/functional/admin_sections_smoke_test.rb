require File.expand_path("../test_helper", __dir__)

class AdminSectionsSmokeTest < ActionController::TestCase
  tests Admin::SectionsController

  def setup
    super
    @request.host = 'admin.local'
    @site = Site.create!(name: 'admin', title: 'admin', host: @request.host)
    @page = Page.create!(site: @site, title: 'page', permalink: 'page')
  end

  test "index responds" do
    def @controller.render(*); head :ok; end
    def @controller.require_authentication; end
    get :index, params: { site_id: @site.id }
    assert_response :success
  end
end
