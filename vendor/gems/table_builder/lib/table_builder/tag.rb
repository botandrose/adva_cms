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

    module HtmlHelper
      def content_tag(name, content = nil, options = {})
        attrs = options.map { |k, v| %(#{k}="#{ERB::Util.html_escape(v)}") }.join(' ')
        attrs = " #{attrs}" unless attrs.empty?
        "<#{name}#{attrs}>#{content}</#{name}>"
      end
    end

    include HtmlHelper

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
      content = '' if content.nil?
      yield(content) if content.empty? && block_given?
      content = content.respond_to?(:html_safe) ? content.html_safe : content.to_s
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
