class Admin::CellsController < Admin::BaseController
  def index
    @cells = []
    render plain: ""
  end
end
