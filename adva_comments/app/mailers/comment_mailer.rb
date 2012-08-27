class CommentMailer < ActionMailer::Base
  default :content_type => "text/html"

  def comment_notification comment
    @comment = comment
    mail :to => comment.site.email, :from => comment.site.email, :subject => "#{comment.site.name}: New pending comment"
  end
end
