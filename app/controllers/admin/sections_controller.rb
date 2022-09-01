class Admin::SectionsController < Admin::BaseController
  before_action :set_section, :only => [:edit, :update, :destroy]
  before_action :normalize_params, :only => :update_all

  after_action :clear_static_cache, :only => [:create, :update, :update_all, :destroy]

  def index
    @sections = @site.sections
  end

  def new
    @section = @site.sections.build(:type => Section.types.first)
  end

  def create
    @section = @site.sections.build params[:section]
    if @section.save
      flash[:notice] = t(:'adva.sections.flash.create.success')
      redirect_to (params[:commit] == t(:'adva.sections.links.save_and_create_new') ? 
        [:new, :admin, :section] :
        [:admin, @section, :articles])
    else
      flash.now[:error] = t(:'adva.sections.flash.update.failure')
      render :action => "new"
    end
  end

  def edit
  end

  def update
    if @section.update params[:section]
      flash[:notice] = t(:'adva.sections.flash.update.success')
      redirect_to [:edit, :admin, @section]
    else
      flash.now[:error] = t(:'adva.sections.flash.update.failure')
      render :action => 'edit'
    end
  end

  def destroy
    if @section.destroy
      flash[:notice] = t(:'adva.sections.flash.destroy.success')
      redirect_to [:new, :admin, :section]
    else
      flash.now[:error] = t(:'adva.sections.flash.destroy.failure')
      render :action => 'edit'
    end
  end

  def update_all
    params[:sections].each do |id, attrs|
      section = Section.find(id)
      parent = Section.find_by(id: attrs[:parent_id])
      left = Section.find_by_id attrs[:left_id]
      if parent
        content.move_to_child_with_index parent, 0
      else
        section.move_to_root
        section.move_to_left_of section.siblings.first
      end
      section.move_to_right_of left if left
    end
    head :ok
  end

  protected

    def set_menu
      @menu = Menus::Admin::Sections.new
    end

    def set_section
      @section = @site.sections.find_by_permalink!(params[:id])
    end

    def normalize_params(hash = nil)
      hash ||= params
      hash.each do |key, value|
        if value.is_a? Hash
          hash[key] = normalize_params(value)
        elsif value == 'null'
          hash[key] = nil
        end
      end
      hash
    end

    def clear_static_cache
      @site.touch
    end

end
