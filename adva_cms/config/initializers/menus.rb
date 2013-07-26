# require_relative "../../vendor/plugins/tags/init"

module Menus
  class Sections < Menu::Menu
    define do
      id :sections
      @site.sections.select { |s| s.published?(true) }.each { |section| item section.title, :action => :show, :resource => section }
    end
  end

  module Admin
    class Sites < Menu::Group
      define do
        namespace :admin
        id :sites
        breadcrumb :site, :content => link_to(@site.name, [:admin, @site]) if @site && !@site.new_record?

        menu :left, :class => 'main' do
          item :sites, :action => :index, :resource => :site if Site.multi_sites_enabled
          if @site && !@site.new_record?
            item :overview, :action => :show,  :resource => @site
            item :sections, :action => :index, :resource => [@site, :section],
              :type => Menu::SectionsMenu,
              :populate => lambda { |scope| @site.sections }
          end
        end

        menu :right, :class => 'right' do
          if @site && !@site.new_record?
            item :settings, :action => :edit,  :resource => @site
          end
          item :users, :action => :index, :resource => [@site, :user]
        end
      end

      class Main < Menu::Group
        define do
          id :main
          parent Sites.new.build(scope).find(:sites)
          menu :actions, :class => 'actions' do
            item :new, :action => :new, :resource => :site
          end
        end
      end
    end

    class Sections < Menu::Group
      define do
        id :main
        parent Sites.new.build(scope).find(:sections)

        if @section and !@section.new_record?
          type = "Menus::Admin::Sections::#{@section.type}".constantize rescue Content
          menu :left, :class => 'left', :type => type
          menu :actions, :class => 'actions' do
            item :delete, :content  => link_to_delete(@section)
          end
        else
          menu :left, :class => 'left' do
            item :sections, :action => :index, :resource => [@site, :section]
          end
          menu :actions, :class => 'actions' do
            activates object.parent.find(:sections)
            item :new, :action => :new, :resource => [@site, :section]
            if !@section and @site.sections.size > 1
              item :reorder, :content => link_to_index(:'adva.links.reorder', [@site, :section], :id => 'reorder_sections', :class => 'reorder')
            end
          end
        end
      end

      class Content < Menu::Menu
        define do
          item :section, :content => content_tag(:h4, "#{@section.title}:")
          item :contents, :content => link_to("Contents", [:admin, @site, @section, :contents])
          item :categories, :action => :index, :resource => [@section, :category]
          item :settings,   :action => :edit,  :resource => @section
        end
      end
    end

    class Contents < Menu::Group
      define do
        id :main
        parent Sites.new.build(scope).find(:sections)

        menu :left, :class => 'left', :type => Sections::Content
        menu :actions, :class => 'actions' do
          activates object.parent.find(:contents)
          @section.class.content_types.each do |content_type|
            item :"new_#{content_type.underscore}", :content => link_to("New #{content_type.underscore.titleize}", [:new, :admin, @site, @section, content_type.underscore.to_sym])
          end
          if @content and !@content.new_record?
            item :show,   :content  => link_to("Show", [@section, @content])
            item :edit,   :content  => link_to("Edit", [:edit, :admin, @site, @section, @content])
            item :delete, :content  => link_to("Delete", [:admin, @site, @section, @content], :method => :delete)
          elsif @contents and @section.contents.size > 1
            item :reorder, :content => link_to("Reorder", [:admin, @site, @section, :contents], :id => 'reorder_contents', :class => 'reorder')
          end
        end
      end
    end

    class Articles < Menu::Group
      define do
        id :main
        parent Sites.new.build(scope).find(:sections)

        menu :left, :class => 'left', :type => Sections::Content
        menu :actions, :class => 'actions' do
          activates object.parent.find(:contents)
          @section.class.content_types.each do |content_type|
            item :"new_#{content_type.underscore}", :content => link_to("New #{content_type.underscore.titleize}", [:new, :admin, @site, @section, content_type.underscore.to_sym])
          end
          if @article and !@article.new_record?
            item :show,   :content  => link_to("Show", [@section, @article])
            item :edit,   :content  => link_to("Edit", [:edit, :admin, @site, @section, @article])
            item :delete, :content  => link_to("Delete", [:admin, @site, @section, @article], :method => :delete)
          end
        end
      end
    end

    class Links < Menu::Group
      define do
        id :main
        parent Sites.new.build(scope).find(:sections)

        menu :left, :class => 'left', :type => Sections::Content
        menu :actions, :class => 'actions' do
          activates object.parent.find(:contents)
          @section.class.content_types.each do |content_type|
            item :"new_#{content_type.underscore}", :content => link_to("New #{content_type.underscore.titleize}", [:new, :admin, @site, @section, content_type.underscore.to_sym])
          end
          if @link and !@link.new_record?
            item :show,   :content  => link_to("Show", [@section, @link])
            item :edit,   :content  => link_to("Edit", [:edit, :admin, @site, @section, @link])
            item :delete, :content  => link_to("Delete", [:admin, @site, @section, @link], :method => :delete)
          end
        end
      end
    end

    class Categories < Menu::Group
      define do
        id :main
        parent Sites.new.build(scope).find(:sections)

        menu :left, :class => 'left', :type => Sections::Content
        menu :actions, :class => 'actions' do
          activates object.parent.find(:categories)
          item :new, :action => :new, :resource => [@section, :category]
          if @category && !@category.new_record?
            item :edit,   :action  => :edit,   :resource => @category
            item :delete, :content  => link_to("Delete", [:admin, @site, @section, @category], :method => :delete)
          elsif !@category and @section.categories.size > 1
            item :reorder, :content => link_to_index(:'adva.links.reorder', [@section, :category], :id => 'reorder_categories', :class => 'reorder')
          end
        end
      end
    end

    class SettingsBase < Menu::Group
      define do
        id :main
        parent Sites.new.build(scope).find(:settings)
        menu :left, :class => 'left' do
          item :settings, :action => :edit,  :resource => @site
          item :cache,    :action => :index, :resource => [@site, :cached_page]
        end
      end
    end

    class Settings < SettingsBase
      define do
        menu :actions, :class => 'actions' do
          item :delete,   :content => link_to_delete(@site)
        end
      end
    end
  end
end
