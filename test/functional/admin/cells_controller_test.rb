require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class AdminCellsControllerTest < ActionController::TestCase
  tests Admin::CellsController

  with_common :access_granted

  test "is an Admin::BaseController" do
    assert_kind_of Admin::BaseController, @controller
  end

  describe "GET to :index" do
    action { get :index }

    it_assigns :cells
    it "responds successfully" do
      assert_response :success
    end
  end
end

