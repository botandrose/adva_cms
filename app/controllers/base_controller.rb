class BaseController < ApplicationController
  class SectionRoutingError < ActionController::RoutingError; end
  helper :base, :resource, :content, :meta_tags
  helper HasFilter::Helper
  helper TableBuilder

  include CacheableFlash
  include ContentHelper
  include ResourceHelper

  before_action :set_site, :set_timezone
  attr_accessor :site, :section

  layout 'default'

  def site
    @site ||= Site.find_by_host!(request.host)
  end

  protected

    alias :set_site :site

    def sections
      @sections ||= site.sections
    end
    helper_method :sections

    def set_section
      @section ||= begin
        sections.find_by_permalink(params[:section_permalink]) || sections.first
      end
      raise ActiveRecord::RecordNotFound unless @section.published?(true) || current_user.admin?
      @section
    end
    alias :section :set_section

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
end

