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
          if @site && !@site.new_record?
            item :overview, :action => :show,  :url => "/admin/site"
            item :sections, :action => :index, :resource => :section,
              :type => Menu::SectionsMenu,
              :populate => lambda { |scope| @site.sections }
          end
        end

        menu :right, :class => 'right' do
          if @site && !@site.new_record?
            item :settings, :action => :edit,  :resource => @site
          end
          item :users, :action => :index, :resource => [:user]
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
          type = "Menus::Admin::Sections::#{@section.type}".constantize rescue Sections::Content
          menu :left, :class => 'left', :type => type
          menu :actions, :class => 'actions' do
            item :delete, :content => link_to("Delete", [:admin, @section], method: "delete")
          end
        else
          menu :left, :class => 'left' do
            item :sections, :action => :index, :resource => :section
          end
          menu :actions, :class => 'actions' do
            activates object.parent.find(:sections)
            item :new, :action => :new, :resource => [@site, :section]
            if !@section and @site.sections.size > 1
              item :reorder, :content => link_to_index(:'adva.links.reorder', :section, :id => 'reorder_sections', :class => 'reorder')
            end
          end
        end
      end

      class Content < Menu::Menu
        define do
          item :section,    :content => content_tag(:h4, "#{@section.title}:")
          item :contents,   :content => link_to("Contents", [:admin, @section, :contents])
          item :categories, :content => link_to("Categories", [:admin, @section, :categories])
          item :settings,   :content => link_to("Settings", [:edit, :admin, @section])
        end
      end
    end

    class Contents < Menu::Group
      define do
        id :main
        parent Sites.new.build(scope).find(:sections)

        type = "Menus::Admin::Sections::#{@section.type}".constantize rescue Sections::Content
        menu :left, :class => 'left', :type => type
        menu :actions, :class => 'actions' do
          activates object.parent.find(:contents)
          @section.class.content_types.each do |content_type|
            item :"new_#{content_type.underscore}", :content => link_to("New #{content_type.underscore.titleize}", [:new, :admin, @section, content_type.underscore.to_sym])
          end
          if @content and !@content.new_record?
            item :show,   :content  => link_to("Show", [@section, @content])
            item :edit,   :content  => link_to("Edit", [:edit, :admin, @section, @content])
            item :delete, :content  => link_to("Delete", [:admin, @section, @content], :method => :delete)
          elsif @contents and @section.contents.size > 1
            item :reorder, :content => link_to("Reorder", [:admin, @section, :contents], :id => 'reorder_contents', :class => 'reorder')
          end
        end
      end
    end

    class Articles < Menu::Group
      define do
        id :main
        parent Sites.new.build(scope).find(:sections)

        type = "Menus::Admin::Sections::#{@section.type}".constantize rescue Sections::Content
        menu :left, :class => 'left', :type => type
        menu :actions, :class => 'actions' do
          activates object.parent.find(:contents)
          @section.class.content_types.each do |content_type|
            item :"new_#{content_type.underscore}", :content => link_to("New #{content_type.underscore.titleize}", [:new, :admin, @section, content_type.underscore.to_sym])
          end
          if @article and !@article.new_record?
            item :show,   :content  => link_to("Show", [@section, @article])
            item :edit,   :content  => link_to("Edit", [:edit, :admin, @section, @article])
            item :delete, :content  => link_to("Delete", [:admin, @section, @article], :method => :delete)
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
            item :"new_#{content_type.underscore}", :content => link_to("New #{content_type.underscore.titleize}", [:new, :admin, @section, content_type.underscore.to_sym])
          end
          if @link and !@link.new_record?
            item :show,   :content  => link_to("Show", [@section, @link])
            item :edit,   :content  => link_to("Edit", [:edit, :admin, @section, @link])
            item :delete, :content  => link_to("Delete", [:admin, @section, @link], :method => :delete)
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
            item :delete, :content  => link_to("Delete", [:admin, @section, @category], :method => :delete)
          elsif !@category and @section.categories.size > 1
            item :reorder, :content => link_to("Reorder", [:admin, @section, :categories], :id => 'reorder_categories', :class => 'reorder')
          end
        end
      end
    end

    class Settings < Menu::Group
      define do
        id :main
        parent Sites.new.build(scope).find(:settings)
      end
    end

    class Users < Menu::Group
      define do
        id :main
        parent Sites.new.build(scope).find(:users)

        menu :left, :class => 'left' do
          item :users, :action => :index, :resource => :user
        end
        menu :actions, :class => 'actions' do
          activates object.parent.find(:users)
          item :new, :action => :new, :resource => :user
          if @user && !@user.new_record?
            item :show,   :url => admin_user_path(@user)
            item :edit,   :url => edit_admin_user_path(@user)
            # item :show,   :action  => :show, :resource => @user
            # item :edit,   :action  => :edit, :resource => @user
            item :delete, :content => link_to("Delete", [:admin, @user], :method => :delete)
          end
        end
      end
    end
  end
end
