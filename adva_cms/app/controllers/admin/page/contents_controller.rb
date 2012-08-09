class Admin::Page::ContentsController < Admin::BaseController
  default_param :content, :author_id, :only => [:create, :update], &lambda { current_user.id }

  before_filter :protect_single_content_mode
  before_filter :set_section
  before_filter :set_categories, :only => [:new, :edit]

  guards_permissions :content, :update => :update_all

  def index
    @contents = @section.contents #.filtered params[:filters]
  end

  def update_all
    params[:contents].each do |id, attrs|
      content = Content.find id
      if attrs[:parent_id] =~ /^\d+$/
        content.move_to_child_of attrs[:parent_id]
      else
        content.move_to_root
      end
      content.move_to_right_of attrs[:left_id] if attrs[:left_id]
    end
    render :text => 'OK'
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
      if params[:action] == 'index' and @section.try(:single_article_mode)
        redirect_to @section.contents.empty? ?
          new_admin_article_url(@site, @section, :content => { :title => @section.title }) :
          edit_admin_article_url(@site, @section, @section.articles.first)
      end
    end
end

