class CommentsController < BaseController
  # TODO apparently it is not possible to use protect_from_forgery with
  # page cached forms? is that correct? as protect_from_forgery seems to
  # validate the form token against the session and ideally when all pages
  # and assets are cached there is no session at all this seems to make sense.
  #
  # Rails docs say: "done by embedding a token based on the session ... in all
  # forms and Ajax requests generated by Rails and then verifying the authenticity
  # of that token in the controller"
  # http://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection/ClassMethods.html
  #
  # Note: Could fetch forgery token via AJAX?

  protect_from_forgery :except => [:preview, :create]

  authenticates_anonymous_user
  layout 'default'

  before_action :set_section
  before_action :set_comment, :only => [:show, :update, :destroy]
  before_action :set_commentable, :only => [:show, :preview, :create]

  before_action :are_you_a_human_or_not, :only => :create

  guards_permissions :comment, :except => :show, :create => :preview

  def show
  end

  def preview
    @comment = @commentable.comments.build(comment_params)
    @comment.send(:process_filters)
    render :layout => false
  end

  def create
    @comment = @commentable.comments.build(comment_params)
    if @comment.save
      trigger_events @comment
      CommentMailer.comment_notification(@comment).deliver_later
      if current_user.anonymous?
        flash.notice = "Your comment is being reviewed, and will be posted shortly. Thank you for commenting!"
      else
        @comment.update_column :approved, true
        flash.notice = "You're an admin, so your comment is being posted immediately! Refresh the page to see it."
      end
      respond_to do |format|
        format.html { redirect_to "#{request.env['HTTP_REFERER']}#comments" }
        format.js { render json: true }
      end
    else
      flash[:error] = @comment.errors.full_messages.to_sentence # TODO hu.
      respond_to do |format|
        format.html { redirect_to "#{request.env['HTTP_REFERER']}#comments" }
        format.js { render json: false }
      end
    end
  end

  def update
    if @comment.update(comment_params)
      trigger_events(@comment)
      flash.notice = t(:'adva.comments.flash.update.success')
      render json: true
    else
      set_commentable
      flash[:error] = @comment.errors.full_messages.to_sentence
      render json: false
    end
  end

  def destroy
    @comment.destroy
    trigger_events @comment
    redirect_to "/", notice: t(:'adva.comments.flash.destroy.success')
  end

  protected

  def comment_params
    params.require(:comment).permit(
      :author_email,
      :author_name,
      :body,
      :commentable_id,
      :commentable_type,
    ).merge(site_id: @commentable.site_id, section_id: @commentable.section_id)
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def set_commentable
    @commentable = if @comment
      @comment.commentable or raise ActiveRecord::RecordNotFound
    else
      begin
        klass = params.dig(:comment, :commentable_type).constantize
        raise NameError unless klass.has_many_comments?
      rescue NameError
        raise ActiveRecord::RecordNotFound
      end
      klass.find(params.dig(:comment, :commentable_id))
    end
  end

  def current_resource
    @comment || @commentable
  end
end
