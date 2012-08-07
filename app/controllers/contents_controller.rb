class ContentsController < BaseController
  include ActionController::GuardsPermissions::InstanceMethods
  helper :roles

  before_filter :guard_view_permissions, :only => [:index, :show]

  acts_as_commentable
  authenticates_anonymous_user

  def index
    @section = Section.find_by_permalink! params[:section_permalink]
    @contents = @section.contents.published
    redirect_to [@section, @contents.first]
  end

  def show
    @section = Section.find_by_permalink! params[:section_permalink]
    @content = @section.contents.find_by_permalink! params[:permalink], :include => :author

    if skip_caching? or stale?(:etag => @content, :last_modified => [@content, @section, @site].collect(&:updated_at).compact.max.utc, :public => true)
      render :template => "#{@section.type.tableize}/articles/show"
    end
  end

  protected

  def guard_view_permissions
    if @content.try(:draft?) and not has_permission?('update', 'content')
      raise ActiveRecord::RecordNotFound
    end
  end
end
