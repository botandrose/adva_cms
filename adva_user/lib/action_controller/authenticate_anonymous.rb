# Auto-registers and re-authenticates anonymous users based on a single token
# that's stored in the session. This is for anonymous posting of blog comments,
# editing wikipages etc. and allows to do such things as:
#
# * store user information in the user table (which keeps the model and db
#   structure clean) and
# * allow users to (e.g.) edit their comment based on this anonymous login.

module ActionController
  module AuthenticateAnonymous
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def authenticates_anonymous_user
        return if authenticates_anonymous_user?
        include InstanceMethods
        prepend Module.new {
          def current_user
            @current_user ||= (super || login_or_register_anonymous)
          end

          def authenticated?
            !!current_user and !current_user.anonymous?
          end
        }
      end

      def authenticates_anonymous_user?
        included_modules.include? InstanceMethods
      end
    end

    module InstanceMethods
      def login_or_register_anonymous
        anonymous = try_login_anonymous || User.anonymous
        anonymous = register_or_update_anonymous anonymous if params[:user]
        login_anonymous! anonymous if anonymous
        anonymous
      end

      def try_login_anonymous
        # try to authenticate if token is present
        validate_token User, session[:anonymous_token] if session[:anonymous_token]
      end

      def register_or_update_anonymous(anonymous)
        # if :name and :email params are passed either register a new Anonymous or update the existing one
        anonymous.update params[:user].merge(request_info)
        anonymous
      end

      def login_anonymous!(anonymous)
        # set a new session token and expiration
        token = anonymous.assign_token('anonymous', 3.hour.from_now)
        anonymous.save
        session[:anonymous_token] = "#{anonymous.id};#{token}"
        cookies[:aid] = anonymous.id.to_s unless anonymous.new_record?
      end

      def request_info
        { :ip      => request.env["REMOTE_ADDR"],
          :agent   => request.env["HTTP_USER_AGENT"],
          :referer => request.env["HTTP_REFERER"] }
      end
    end
  end
end
