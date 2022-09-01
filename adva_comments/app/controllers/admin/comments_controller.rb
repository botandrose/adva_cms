class Admin::CommentsController < Admin::BaseController
  layout "admin"

  before_action :set_comment, :only => [:edit, :update, :destroy]
  before_action :set_commentable, :set_comment_params, :only => :create
  after_action :postback_spaminess, :only => [:update]

  def index
    # FIXME how to remove the Topic dependency here? 
    # maybe make Comment a subclass of Comment::Base or something so that we can use STI to exclude 
    # special comment types?
    @comments = @site.comments.where(['commentable_type NOT IN (?)', 'Topic']).
      reorder("comments.created_at DESC").
      paginate(:page => current_page, :per_page => 25)
  end

  def edit
  end

  def update
    if @comment.update params[:comment]
      trigger_events @comment
      flash[:notice] = t(:'adva.comments.flash.update.success')
      redirect_to params[:return_to] || admin_comments_url
    else
      flash.now[:error] = t(:'adva.comments.flash.update.failure')
      render :action => :edit
    end
  end

  def destroy
    @comment.destroy
    trigger_events @comment
    flash[:notice] = t(:'adva.comments.flash.destroy.success')
    redirect_to params[:return_to] || admin_comments_url
  end

  private

    def set_menu
      @menu = Menus::Admin::Comments.new
    end

    def set_commentable
      type, id = params[:comment].values_at(:commentable_type, :commentable_id)
      @commentable = type.constantize.find id
    end

    def set_comment_params
      params[:comment].merge! :site_id => @commentable.site_id,
                              :section_id => @commentable.section_id,
                              :author => current_user
    end

    def set_comment
      @comment = Comment.find(params[:id])
    end
    
    def filter_options options
      case params[:filter]
      when 'state'
        params[:state] == 'approved' ? options[:conditions] = "approved = '1'" : options[:conditions] = "approved = '0'"
      when 'body'
        options[:conditions] = Comment.send(:sanitize_sql, ["LOWER(body) LIKE :query", {:query => "%#{params[:query].downcase}%"}])
      when 'author_name'
        options[:conditions] = Comment.send(:sanitize_sql, ["LOWER(author_name) LIKE :query", {:query => "%#{params[:query].downcase}%"}])
      when 'author_email'
        options[:conditions] = Comment.send(:sanitize_sql, ["LOWER(author_email) LIKE :query", {:query => "%#{params[:query].downcase}%"}])
      when 'author_homepage'
        options[:conditions] = Comment.send(:sanitize_sql, ["LOWER(author_homepage) LIKE :query", {:query => "%#{params[:query].downcase}%"}])
      end
      options
    end

    def postback_spaminess
      if @comment.approved_changed? and @site.respond_to?(:spam_engine)
        spaminess = @comment.approved? ? :ham : :spam
        @site.spam_engine.mark_spaminess(spaminess, @comment, :url => show_url(@comment.commentable))
      end
    end

    def current_resource
      @comment ? @comment.commentable : @content || @section || @site
    end
end

