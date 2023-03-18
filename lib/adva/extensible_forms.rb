require 'action_view'
require 'action_view/helpers'
require 'action_view/helpers/form_helper'

module ActionView
  module Helpers
    module FormHelper
      def field_set(object_name, name, content = nil, options = {}, &block)
        options.delete(:object)
        options[:name] ||= name
        options[:id] ||= name
        content ||= self.capture(&block) if block_given?
        content_tag("fieldset", raw(content), options).html_safe
      end

      protected

      def singular_class_name(name)
        ActiveModel::Naming.singular(name)
      end

      def pick_form_builder(name)
        name = "#{name.to_s.classify}FormBuilder"
        name.constantize
      rescue NameError
        Object.const_set(name, Class.new(ActionView::Base.default_form_builder)) rescue ActionView::Base.default_form_builder
      end
    end
  end
end

module Adva
  class ExtensibleFormBuilder < ActionView::Helpers::FormBuilder
    class_attribute :callbacks
    self.callbacks = { :before => {}, :after => {} }

    class_attribute :tabs
    self.tabs = []

    class_attribute :options
    self.options = { :labels => false, :wrap => false, :default_class_names => {} }

    class << self
      [:labels, :wrap].each do |option|
        define_method(:"#{option}=") { |value| self.options[option] = value }
      end

      def default_class_names(type = nil)
        if type
          self.options[:default_class_names][type] ||= []
        else
          self.options[:default_class_names]
        end
      end

      def before(object_name, method, string = nil, &block)
        add_callback(:before, object_name, method, string || block)
      end

      def after(object_name, method, string = nil, &block)
        add_callback(:after, object_name, method, string || block)
      end

      def tab(name, options = {}, &block)
        self.tabs.reject! { |n, b| name == n }
        self.tabs += [[name, block]]
      end

      protected

        def add_callback(stage, object_name, method, callback)
          method = method.to_sym
          callbacks[stage][object_name] ||= { }
          callbacks[stage][object_name][method] ||= []
          callbacks[stage][object_name][method] << callback
        end
    end

    helpers = field_helpers + %w(select date_select datetime_select time_select time_zone_select collection_select) -
                              %w(hidden_field label fields_for apply_form_for_options!)

    helpers.each do |method_name|
      class_eval <<-src, __FILE__, __LINE__
        def #{method_name}(*args, &block)
          type = #{method_name.to_sym.inspect}

          options = args.extract_options!
          options = add_default_class_names(options, type)
          # options = add_tabindex(options, type)

          label, wrap, hint = options.delete(:label), options.delete(:wrap), options.delete(:hint)
          name = args.first

          with_callbacks(name) do
            tag = super(*(args << options), &block)
            # remember_tabindex(tag, options)
            tag = hint(tag, hint) if hint
            tag = labelize(type, tag, name, label) if label || self.options[:labels]
            tag = wrap(tag) if wrap || self.options[:wrap]
            tag
          end
        end
      src
    end

    def field_set(*args, &block)
      options = args.extract_options!
      options = add_default_class_names(options, :field_set)

      name    = args.first
      name ||= :default_fields

      @template.concat with_callbacks(name) {
        legend = options.delete(:legend) || ''
        legend = @template.content_tag('legend', legend) unless legend.blank?
        @template.field_set(@object_name, name, nil, objectify_options(options)) do
          legend.to_s + (block ? block.call.to_s : '')
        end
      }
    end

    def tabs
      yield if block_given?
      assign_ivars!
      @template.content_tag(:div, :class => 'tabs') {
        @template.content_tag(:ul) {
          self.class.tabs.map { |name, block|
            klass = self.class.tabs.first.first == name ? 'active' : nil
            @template.content_tag 'li', @template.link_to(I18n.t(name, :scope => :'adva.titles'), "##{name}"), :class => klass
          }.join.html_safe
        } +
        self.class.tabs.map { |name, block|
          klass = self.class.tabs.first.first == name ? 'tab active' : 'tab'
          @template.content_tag 'div', block.call(self), :id => "tab_#{name}", :class => klass
        }.join.html_safe
      }.html_safe
    end

    def tab(name, &block)
      with_callbacks(:"tab_#{name}") {
        self.class.tab(name, &block)
      }
    end

    def buttons(name = :submit_buttons, &block)
      @template.concat with_callbacks(name) {
        @template.capture { @template.buttons(&block) }
      }
    end

    def render(*args)
      @template.send(:render, *args)
    end

    protected

    def labelize(type, tag, method, label = nil)
      label = case label
      when String then label
      when Symbol then I18n.t(label)
      when TrueClass then
        scope = [:activerecord, :attributes] + object.class.to_s.underscore.split('/')
        string = I18n.t(method, :scope => scope)
        string.is_a?(String) ? string : method.to_s.titleize
      else nil
      end

      case type
      when :check_box, :radio_button
        tag + self.label(method, label, :class => 'inline light', :for => extract_id(tag), :id => "#{extract_id(tag)}_label")
      else
        self.label(method, label) + tag
      end
    end

    def wrap(tag)
      @template.content_tag(:p, tag)
    end

    def hint(tag, hint)
      hint = I18n.t(hint) if hint.is_a?(Symbol)
      tag + @template.content_tag(:span, hint, :class => 'hint', :for => extract_id(tag))
    end

    def add_default_class_names(options, type)
      options[:class] = (Array(options[:class]) + self.class.default_class_names(type)).join(' ')
      options.delete(:class) if options[:class].blank?
      options
    end

    def tabindex_increment!
      @tabindex_count ||= 0
      @tabindex_count += 1
    end

    def set_tabindex_position(index = nil, position = nil)
      position = case position
      when :after  then tabindexes[index] + 1
      when :before then tabindexes[index] - 1
      when :same   then tabindexes[index]
      else tabindex_increment!
      end
      position
    end

    def add_tabindex(options, type)
      index = options[:tabindex]

      if index.is_a?(Hash)
        key = index.keys.first
        options[:tabindex] = set_tabindex_position(index[key], key)
      elsif index.is_a?(Symbol)
        options[:tabindex] = set_tabindex_position(index, :same)
      elsif index.blank?
        options[:tabindex] = set_tabindex_position
      end

      options
    end

    def tabindexes
      @tabindexes ||= {}
    end

    def remember_tabindex(tag, options)
      id = extract_id(tag)
      tabindexes[:"#{id}"] = options[:tabindex] unless id.blank?
    end

    def with_callbacks(method, &block)
      result = ''
      result += run_callbacks(:before, method) if method
      result += yield.to_s
      result += run_callbacks(:after, method) if method
      result.html_safe
    end

    def run_callbacks(stage, method)
      if callbacks = callbacks_for(stage, method.to_sym)
        callbacks.inject('') do |result, callback|
          result + case callback
            when Proc
              assign_ivars!
              instance_eval(&callback)
            else
              callback
          end.to_s
        end
      end || ''
    end

    def callbacks_for(stage, method)
      object_name = @object_name.try(:to_sym)
      self.callbacks[stage][object_name] and
      self.callbacks[stage][object_name][method.to_sym]
    end

    def assign_ivars!
      unless @ivars_assigned
        @template.assigns.each { |key, value| instance_variable_set("@#{key}", value) }
        vars = @template.controller.instance_variable_names
        vars.each { |name| instance_variable_set(name, @template.controller.instance_variable_get(name)) }
        @ivars_assigned = true
      end
    end

    # yep, we gotta do this crap because there doesn't seem to be a sane way
    # to hook into actionview's form_helper methods
    def extract_id(tag)
      tag =~ /id="([^"]+)"/
      $1
    end
  end
end

ActionView::Base.default_form_builder = Adva::ExtensibleFormBuilder
