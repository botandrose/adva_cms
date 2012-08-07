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
            item :sections, :action => :index, :resource => [@site, :section], :type => Menu::SectionsMenu, :populate => lambda { @site.sections }
            item :comments, :action => :index, :resource => [@site, :comment]
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
          type = @section.class.content_type.underscore
          item :section, :content => content_tag(:h4, "#{@section.title}:")
          item type.pluralize.to_sym, :action => :index, :resource => [@section, type]
          
          if type == 'article'
            if !(@section.try(:single_article_mode) ? @section.single_article_mode : false)
              item :categories, :action => :index, :resource => [@section, :category]
            end
          else
            item :categories, :action => :index, :resource => [@section, :category]
          end
          
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
          item :new_article, :action => :new, :resource => [@site, @section, :article]
          item :new_link,    :action => :new, :resource => [@site, @section, :link]
          if @content and !@content.new_record?
            item :show,   :content  => link_to("Show", [@section, @content])
            item :edit,   :content  => link_to("Edit", [:edit, :admin, @site, @section, @content])
            item :delete, :content  => link_to("Delete", [:admin, @site, @section, @content], :method => :delete)
          elsif !@content and @section.is_a?(Page) and @section.contents.size > 1
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
          item :new_article, :action => :new, :resource => [@section, :article]
          item :new_link,    :action => :new, :resource => [@section, :link] unless @section.is_a?(Blog)
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
          item :new_article, :action => :new, :resource => [@section, :article]
          item :new_link,    :action => :new, :resource => [@section, :link]
          if @link and !@link.new_record?
            item :show,   :content  => link_to_show(@link, :cl => content_locale, :namespace => nil)
            item :edit,   :action   => :edit, :resource => @link
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
