class Admin::Page::CategoriesController < Admin::BaseController
  before_action :set_category, only: [:edit, :update, :destroy]

  def index
  end

  def new
    @category = @section.categories.build
  end

  def create
    @category = @section.categories.build category_params
    if @category.save
      redirect_to [:admin, @section, :categories], notice: "The category has been created."
    else
      flash.now.alert = "The category could not be created." + current_resource_errors
      render action: "new"
    end
  end

  def update
    if @category.update category_params
      redirect_to [:admin, @section, :categories], notice: "The category has been updated."
    else
      flash.now.alert = "The category could not be updated." + current_resource_errors
      render action: "edit"
    end
  end

  # The tree widget posts parent_id/left_id per row. left_id is a positioning
  # hint rather than a column, so move the nodes explicitly the way sections and
  # contents do, instead of mass-assigning whatever was posted.
  def update_all
    params.require(:categories).each do |id, attrs|
      category = @section.categories.find(id)
      parent = @section.categories.find_by(id: attrs[:parent_id])
      left = @section.categories.find_by(id: attrs[:left_id])
      if parent
        category.move_to_child_with_index parent, 0
      else
        category.move_to_root
        sibling = category.siblings.first
        category.move_to_left_of sibling if sibling
      end
      category.move_to_right_of left if left
    end
    @section.categories.update_paths!
    head :ok
  end

  def destroy
    if @category.destroy
      redirect_to [:admin, @section, :categories], notice: "The category has been deleted."
    else
      flash.now.alert = "The category could not be deleted." + current_resource_errors
      render action: "edit"
    end
  end

  protected

    def current_resource
      @category || @section
    end

    def set_menu
      @menu = Menus::Admin::Categories.new
    end

    def set_category
      @category = @section.categories.find(params[:id])
    end

    def category_params
      return {} unless params[:category]
      params.require(:category).permit(:title, :permalink, :parent_id)
    end
end
