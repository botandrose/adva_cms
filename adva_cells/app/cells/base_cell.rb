require "cells"
require "cell/base"
require "tilt"

class BaseCell < Cell::Base
  def self.to_xml(options={})
    options[:root]    ||= 'cell'
    options[:indent]  ||= 2
    options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])

    cell_name = self.to_s.gsub('Cell', '').underscore

    options[:builder].tag!(options[:root]) do |cell_node|
      cell_node.id   cell_name
      cell_node.name cell_name.humanize
      cell_node.states do |states_node|
        self.action_methods.each do |state|
          states_node.state do |state_node|
            state = state.to_s

            template_path = "#{view_paths.first}/#{cell_name}/#{state}_form.html*"
            possible_templates = Dir.glob(template_path)
            template = possible_templates.first
            form = template ? Tilt.new(template).render : ''

            state_node.id          state
            state_node.name        state.humanize
            state_node.description I18n.translate(:"adva.cells.#{cell_name}.states.#{state}.description", :default => '')
            state_node.form        form
          end
        end
      end
    end
  end

  def self.to_json
    cell_name = self.to_s.sub("Cell", "").underscore
    action_methods.map do |state|
      {
        id:   "#{cell_name}/#{state.to_s}",
        name: "#{cell_name.humanize} #{state.to_s.humanize}",
      }
    end
  end

  protected

  def symbolize_options!
    @opts.symbolize_keys!
  end

  def set_site
    @site = controller.site or raise "can not set site from controller"
  end

  def set_section
    if section = @opts[:section]
      @section = @site.sections.find(:first, :conditions => ["id = ? OR permalink = ?", section, section])
    end
    @section ||= controller.section
    @section ||= @site.sections.root
  end

  # TODO make this a class level dsl, so cells can say something like:
  # has_option :include_child_section => {:type => :boolean, :default => true}
  def include_child_sections?
    boolean_option(:include_child_sections)
  end

  def boolean_option(key)
    value = @opts[key]
    !!(value.blank? || value == 'false' || value == '0' ? false : true)
  end

  def with_sections_scope(klass, &block)
    conditions = include_child_sections? ?
      ["(sections.lft >= ?) and (sections.rgt <= ?)", @section.lft, @section.rgt] :
      { :section_id => @section.id }
    options = { :find => { :conditions => conditions, :include => 'section' }}

    klass.send :with_scope, options, &block
  end
end
