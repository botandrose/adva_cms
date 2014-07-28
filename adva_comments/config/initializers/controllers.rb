ActionDispatch::Callbacks.to_prepare do
  BaseController.class_eval do
    helper :comments

    def comments # FIXME why isn't this in acts_as_commentable ?
      @comments = @commentable.approved_comments
      respond_to do |format|
        format.atom { render :template => 'comments/comments', :layout => false }
      end
    end

    private

    # goofy gauranteed-to-be-unique spam filter
    # test for variable sent along with the form. this variable is populated in the form via javascript after one second.
    def are_you_a_human_or_not
      if honeypot_filled? or not_a_real_browser?
        head :not_found and return false if Rails.env.production?
      end
    end

    def honeypot_filled?
      (params[:comment] || {}).delete(:url).present?
    end

    def not_a_real_browser?
      params[:are_you_a_human_or_not] != "if you prick me, do i not bleed?"
    end
  end
  
  Admin::BaseController.helper :comments, :'admin/comments'

  ArticlesController.class_eval do
    acts_as_commentable

    private

    def set_commentable
      set_article if params[:permalink]
      super
    end
  end
end
