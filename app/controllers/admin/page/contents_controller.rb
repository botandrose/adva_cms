class Admin::Page::ContentsController < Admin::BaseController
  default_param :content, :author_id, :only => [:create, :update], &lambda { |*| current_user.id }

  before_action :set_section
  before_action :protect_single_content_mode
  before_action :set_categories, :only => [:new, :edit]

  def index
    @contents = @section.contents #.filtered params[:filters]
  end

  def update_all
    params[:contents].each do |id, attrs|
      content = Content.find id
      parent = Content.find_by_id attrs[:parent_id]
      left = Content.find_by_id attrs[:left_id]
      if parent
        content.move_to_child_with_index parent, 0
      else
        content.move_to_root
        content.move_to_left_of content.siblings.first
      end
      content.move_to_right_of left if left
    end
    head :ok
  end
  
  protected 

    def current_resource
      @content || @section
    end

    def set_menu
      @menu = Menus::Admin::Contents.new
    end

    def set_categories
      @categories = @section.categories.roots
    end

    def protect_single_content_mode
      if params[:action] == 'index' && @section.try(:single_article_mode)
        redirect_to @section.contents.empty? ?
          new_admin_page_article_url(@section, :content => { :title => @section.title }) :
          edit_admin_page_article_url(@section, @section.articles.first)
      end
    end
end
