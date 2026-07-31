module Adva
  module AuthenticateUser
    def self.included(target)
      target.extend(ClassMethods)
      # Opt-in, because #current_user runs on every request: without this a
      # password-reset token in the URL would establish a session anywhere in
      # the app, including the admin area.
      target.class_attribute :perishable_token_login, default: false, instance_writer: false
      target.helper_method(:current_user, :logged_in?, :authenticated?)
    end

    # Methods available as macro-style methods on any controller
    module ClassMethods
      # Sets up the controller so that authentication is required. If
      # the user is not authenticated then they will be redirected to
      # the login screen.
      #
      # The page requested will be saved so that once the login has
      # occured they will be sent back to the page they first
      # requested. If no page was requested (they went to the login
      # page directly) then they will be directed to profiles/home
      # after login which is a placeholder for the app to override.
      #
      # Options given are passed directly to the before_action method
      # so feel free to provide :only and :except options.
      def authentication_required
        before_action :require_authentication
      end

      # Will remove authentication from certain actions. Options given
      # are passed directly to skip_before_action so feel free to use
      # :only and :except options.
      #
      # This method is useful in cases where you have locked down the
      # entire application by putting authentication_required in your
      # ApplicationController but then want to open an action back up
      # in a specific controller.
      def no_authentication_required
        skip_before_action :require_authentication
      end

      # Lets this controller establish a session from a perishable token in the
      # URL. Only the password-reset flow should need this.
      def perishable_token_login!
        self.perishable_token_login = true
      end
    end

    # Logs in with an email/password pair, returning the user on success and
    # false otherwise. Pass :remember_me to outlive the browser session.
    def authenticate_user(credentials)
      credentials = credentials.to_unsafe_h if credentials.respond_to?(:to_unsafe_h)
      credentials = credentials.symbolize_keys

      user_session = UserSession.new(
        email: credentials[:email].to_s,
        password: credentials[:password].to_s,
        remember_me: credentials[:remember_me].present?,
      )
      return false unless user_session.save

      @current_user = user_session.user
      set_user_cookie!(@current_user)
      @current_user
    end

    # Establishes a session for an already-trusted user, skipping password
    # verification, for flows that authenticate by some other means such as a
    # signed token.
    def login_user!(user)
      UserSession.create(user)
      @current_user = user
      set_user_cookie!(user)
      user
    end

    # Will retrieve the current_user. Will not force a login but simply load
    # the current user if a person is logged in.
    #
    # Returns an unsaved anonymous User rather than nil when nobody is logged
    # in, so callers can always talk to a user object.
    def current_user
      @current_user ||= begin
        user = UserSession.find&.user || login_with_perishable_token
        if user
          set_user_cookie!(user)
          user
        else
          User.anonymous
        end
      end
    end

    def authenticated?
      !current_user.anonymous?
    end
    alias :logged_in? :authenticated?

    private

    # Will actually test to see if the user is authorized
    def require_authentication
      # No matter what the app does a user can always login, forgot
      # password and register. The controllers provided by this
      # plugin alreaddy have these controllers/actions on an
      # exception list but this prevents a mistake an overridden
      # controller from preventing the normal login behavior.
      %w(session password user).each do |c|
            %w(new create).each do |a|
          return if (controller_name == c) && (action_name == a)
        end
          end

      # If we cannot get the current user store the requested page
      # and send them to the login page.
      if current_user.anonymous?
        redirect_to login_url(return_to: request.url) and false
      end
    end

    def logout
      UserSession.find&.destroy
      reset_session
      forget_me!
    end

    def forget_me!
      cookies[:remember_me] = nil
      cookies[:uid] = nil
      cookies[:uname] = nil
    end

    def set_user_cookie!(user = current_user)
      unless user.anonymous?
        cookies[:uid] = user.id.to_s
        cookies[:uname] = user.name
      end
    end

    # A password reset link carries a perishable token in the URL. Consuming it
    # logs the user in so they can set a new password.
    def login_with_perishable_token
      return nil unless perishable_token_login

      token = params[:token] if respond_to?(:params, true)
      return nil if token.blank?

      user = User.find_using_perishable_token(token)
      return nil unless user

      UserSession.create(user)
      user
    end
  end
end
