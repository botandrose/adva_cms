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
      # cell_files = Dir[Rails.root + '/app/cells/*.rb'] + Dir[File.join(Rails.root, 'vendor', 'adva', 'engines') + '/*/app/cells/*.rb'] +
      #   Dir[File.join(Rails.root, 'vendor', 'adva', 'plugins') + '/*/app/cells/*.rb']
      cell_files = Dir[Rails.root + '/app/cells/*.rb'] + Dir[File.join(Rails.root, 'vendor', 'plugins') + '/*/app/cells/*.rb']
      cell_files.each { |cell_file| require cell_file }
    end
  end
end
