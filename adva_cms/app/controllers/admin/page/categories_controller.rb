class Admin::Page::CategoriesController < Admin::BaseController
  before_filter :set_category, :only => [:edit, :update, :destroy]

  guards_permissions :category, :update => :update_all

  def index
  end

  def new
    @category = @section.categories.build
  end

  def create
    @category = @section.categories.build params[:category]
    if @category.save
      flash[:notice] = t(:'adva.categories.flash.create.success')
      redirect_to [:admin, @site, @section, :categories]
    else
      flash.now[:error] = t(:'adva.categories.flash.create.failure')
      render :action => "new"
    end
  end

  def update
    if @category.update_attributes params[:category]
      flash[:notice] = t(:'adva.categories.flash.update.success')
      redirect_to [:admin, @site, @section, :categories]
    else
      flash.now[:error] = t(:'adva.categories.flash.update.failure')
      render :action => 'edit'
    end
  end

  def update_all
    params[:categories].each do |id, attrs|
      content = @section.categories.find id
      parent = @section.categories.find_by_id attrs[:parent_id]
      left = @section.categories.find_by_id attrs[:left_id]
      if parent
        content.move_to_child_with_index parent, 0
      else
        content.move_to_root
        content.move_to_left_of content.siblings.first
      end
      content.move_to_right_of left if left
    end
    render :text => 'OK'
  end

  def destroy
    if @category.destroy
      flash[:notice] = t(:'adva.categories.flash.destroy.success')
      redirect_to [:admin, @site, @section, :categories]
    else
      flash.now[:error] = t(:'adva.categories.flash.destroy.failure')
      render :action => 'edit'
    end
  end

  protected

    def set_menu
      @menu = Menus::Admin::Categories.new
    end

    def set_category
      @category = @section.categories.find(params[:id])
    end
end
