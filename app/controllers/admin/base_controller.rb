require "adva/authenticate_user"

class Admin::BaseController < ApplicationController
  layout "admin"

  renders_with_error_proc :above_field
  include CacheableFlash
  include ContentHelper
  include ResourceHelper
  helper TableBuilder

  helper :base, :resource, :content

  include Adva::AuthenticateUser

  helper_method :menu, :content_locale, :has_permission?

  before_action :set_menu, :set_site, :set_section, :set_locale, :set_timezone

  authentication_required

  attr_accessor :site

  protected

    def current_resource
      @section || @site || Site.new
    end

    def require_authentication
      if current_user.anonymous?
        return redirect_to_login("Please login to access the admin area of this site.")
      elsif !current_user.admin?
        return redirect_to_login("You do not have permission to access the admin area of this site. Please, contact your system administrator or login with another user account.")
      end
    end

    def redirect_to_login(notice = nil)
      redirect_to login_url(return_to: request.url), notice: notice
    end

    def return_from(action, options = {})
      CGI.unescape(params[:return_to] || begin
        url = Registry.get(:redirect, action)
        url = Registry.get(:redirect, url) if url.is_a?(Symbol)
        url = url.call(self) if url.is_a?(Proc)
        url || options[:default] || '/'
      end)
    end

    def current_page
      @page ||= params[:page].present? ? params[:page].to_i : 1
    end

    def menu
      @menu ||= Menus::Admin::Sites.new
    end
    alias_method :set_menu, :menu

    def set_locale
      params[:locale] =~ /^[\w]{2}$/ or raise 'invalid locale' if params[:locale]
      I18n.locale = params[:locale] || I18n.default_locale
    end

    def set_timezone
      Time.zone = @site.timezone if @site
    end

    def set_site
      @site = Site.find_by_host!(request.host)
    end

    def set_section
      params[:section_id] = params.delete(:page_id) if params[:page_id]
      params[:section_id] = params.delete(:blog_id) if params[:blog_id]
      params[:section_id] = params.delete(:album_id) if params[:album_id]
      @section = @site.sections.find_by_permalink!(params[:section_id]) if params[:section_id]
    end

    def update_role_context!(params)
      set_section if params[:section_id] and !@section
    end

    def content_locale
      "en"
      # ActiveRecord::Base.locale == I18n.default_locale ? nil : ActiveRecord::Base.locale
    end

    def current_resource_errors
      current_resource.errors.full_messages.map { |msg| "<li>#{msg}</li>" }.join
    end
end
