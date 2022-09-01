class Admin::BaseController < ApplicationController
  layout "admin"

  renders_with_error_proc :above_field
  include CacheableFlash
  include ContentHelper
  include ResourceHelper
  helper TableBuilder

  helper :base, :resource, :content, :meta_tags
  helper HasFilter::Helper

  helper_method :menu, :content_locale, :has_permission?

  before_action :set_menu, :set_site, :set_section, :set_locale, :set_timezone

  authentication_required

  attr_accessor :site

  protected

    def current_resource
      @section || @site || Site.new
    end

    def require_authentication
      if @site
        return redirect_to_login(t(:'adva.flash.login_to_access_admin_area_of_site')) if current_user.anonymous?
        unless current_user.has_permission_for_admin_area?(@site)
          return redirect_to_login(t(:'adva.flash.no_permission_for_admin_area_of_site'))
        end
      else
        return redirect_to_login(t(:'adva.flash.login_to_access_admin_area_of_account')) if current_user.anonymous?
        unless current_user.has_global_role?(:superuser)
          return redirect_to_login(t(:'adva.flash.no_permission_for_admin_area_of_account'))
        end
      end
    end

    def redirect_to_login(notice = nil)
      flash[:notice] = notice
      redirect_to login_url(:return_to => request.url)
    end

    def rescue_action(exception)
      if exception.is_a? ActionController::RoleRequired
        @error = exception
        render :template => 'shared/messages/insufficient_permissions'
      else
        super
      end
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
      I18n.locale.untaint
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
