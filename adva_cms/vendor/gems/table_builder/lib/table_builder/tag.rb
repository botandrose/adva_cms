module TableBuilder
  class Tag
    class << self
      attr_accessor :level, :tag_name
    end

    def level
      self.class.level
    end

    def tag_name
      self.class.tag_name
    end

    include ActionView::Helpers::TagHelper

    attr_reader :options, :parent

    def initialize(parent = nil, options = {})
      @parent = parent
      @options = options
    end
    
    def collection_class
      table.collection_class
    end
    
    def collection_name
      table.collection_name
    end
    
    def table
      is_a?(Table) ? self : parent.try(:table)
    end
    
    def head?
      is_a?(Head) || !!parent.try(:head?)
    end

    def render(content = nil)
      yield(content = '') if content.nil? && block_given?
      content = content.html_safe
      content_tag(tag_name, content, options)
    end
    
    def add_class(klass)
      add_class!(options, klass)
    end
    
    protected
      def add_class!(options, klass)
        unless klass.blank?
          options[:class] ||= ''
          options[:class] = options[:class].split(' ').push(klass).join(' ')
        end
      end
  end
end
