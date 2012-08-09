class Admin::SectionsController < Admin::BaseController
  before_filter :set_section, :only => [:edit, :update, :destroy]
  before_filter :normalize_params, :only => :update_all

  after_filter :clear_static_cache, :only => [:create, :update, :update_all, :destroy]
  guards_permissions :section, :update => :update_all

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
        [:new, :admin, @site, :section] :
        [:admin, @site, @section, :articles])
    else
      flash.now[:error] = t(:'adva.sections.flash.update.failure')
      render :action => "new"
    end
  end

  def edit
  end

  def update
    if @section.update_attributes params[:section]
      flash[:notice] = t(:'adva.sections.flash.update.success')
      redirect_to [:edit, :admin, @site, @section]
    else
      flash.now[:error] = t(:'adva.sections.flash.update.failure')
      render :action => 'edit'
    end
  end

  def destroy
    if @section.destroy
      flash[:notice] = t(:'adva.sections.flash.destroy.success')
      redirect_to [:new, :admin, @site, :section]
    else
      flash.now[:error] = t(:'adva.sections.flash.destroy.failure')
      render :action => 'edit'
    end
  end

  def update_all
    params[:sections].each do |id, attrs|
      section = Section.find id
      if attrs[:parent_id].nil?
        section.move_to_root
      else
        section.move_to_child_of attrs[:parent_id]
      end
      section.move_to_right_of attrs[:left_id] if attrs[:left_id]
    end
    render :text => 'OK'
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
