class PasswordMailer < ActionMailer::Base
  class << self
    def handle_user_password_reset_requested!(event)
      reset_password_email(
        :user => event.object, 
        :from => site(event.source.site).email_from,
        :reset_link => password_reset_link(event.source, event.token), 
        :token => event.token
      ).deliver_now
    end

    def handle_user_password_updated!(event)
      updated_password_email(
        :user => event.object, 
        :from => site(event.source.site).email_from
      ).deliver_now
    end

    private

    def password_reset_link(controller, token)
      controller.send(:url_for, :action => 'edit', :token => token)
    end
  end
  
  def reset_password_email(attributes = {})
    @user = attributes[:user]
    @reset_link = attributes[:reset_link]
    @token = attributes[:token]
    mail({
      to: attributes[:user].email,
      from: attributes[:from],
      subject: "Forgotten Password",
    })
  end

  def updated_password_email(attributes = {})
    @user = attributes[:user]
    mail({
      to: attributes[:user].email,
      from: attributes[:from],
      subject: "Password Updated",
    })
  end
end

