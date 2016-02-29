require "cells"

class BaseCell < Cell::ViewModel
  def self.to_json
    cell_name = self.to_s.sub("Cell", "").underscore
    action_methods.map do |state|
      {
        id:   "#{cell_name}/#{state.to_s}",
        name: "#{cell_name.humanize} #{state.to_s.humanize}",
      }
    end
  end
end
