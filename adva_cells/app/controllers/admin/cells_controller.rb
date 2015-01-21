class Admin::CellsController < Admin::BaseController
  def index
    @cells = Cell.all

    respond_to do |format|
      format.xml  { render :xml => @cells.to_xml(:root => 'cells', :skip_types => true) }
      format.json { render :json => { cells: @cells.map(&:to_json).flatten } }
    end
  end
end
