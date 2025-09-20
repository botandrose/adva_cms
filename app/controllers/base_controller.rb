require "adva/authenticate_user"

class BaseController < ApplicationController
  class SectionRoutingError < ActionController::RoutingError; end
  helper :base, :resource, :content
  helper TableBuilder

  include CacheableFlash
  include ContentHelper
  include ResourceHelper

  include Adva::AuthenticateUser

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  before_action :set_site, :set_timezone
  attr_accessor :site, :section

  def site
    @site ||= Site.find_by_host!(request.host)
  end

  protected

    alias :set_site :site

    helper_method def sections
      @sections ||= site.sections
    end

    helper_method def section
      @section ||= begin
        if params.key?(:section_permalink)
          sections.find_by_permalink!(params[:section_permalink])
        else
          sections.first
        end
      end
      raise ActiveRecord::RecordNotFound unless @section.published?(true) || (current_user&.admin?)
      @section
    end
    alias :set_section :section

    def set_timezone
      Time.zone = @site.timezone if @site
    end

    def current_page
      @page ||= begin
        page = params[:page].to_i
        page = 1 if page == 0
        page
      end
    end

    def set_commentable
      @commentable = @article || @section || @site
    end

    def rescue_action(exception)
      if exception.is_a?(ActionController::RoleRequired)
        redirect_to_login(exception.message)
      else
        super
      end
    end

    def redirect_to_login(notice = nil)
      redirect_to login_url(return_to: request.url), notice: notice
    end

    def return_from(action, options = {})
      CGI.unescape(params[:return_to] || options[:default] || '/')
    end
    
    def current_resource
      @section || @site
    end

    def skip_caching?
      @skip_caching or @article.try(:draft?)
    end

    def skip_caching!
      @skip_caching = true
    end

    def not_found
      render plain: "Not Found", status: 404
    end
end

