module Cell
  class << self
    def all
      @all ||= begin
        require_all_cells
        BaseCell.subclasses
      end
    end

    private
    def require_all_cells
      # TODO pull in cells from engines, too
      cell_files = Dir[::Rails.root.join('app/cells/*.rb')]
      cell_files.each { |cell_file| require cell_file }
    end
  end
end
