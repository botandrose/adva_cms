class BaseController < ApplicationController
  class SectionRoutingError < ActionController::RoutingError; end
  helper :base, :resource, :content
  helper HasFilter::Helper
  helper TableBuilder

  include CacheableFlash
  include ContentHelper
  include ResourceHelper

  before_filter :set_site, :set_timezone
  attr_accessor :site, :section

  layout 'default'

  protected
    def set_site
      @site ||= Site.includes(:sections).find_by_host!(request.host_with_port) # or raise "can not set site from host #{request.host_with_port}"
    end
    alias :site :set_site

    def sections
      @sections ||= site.sections.includes(:contents)
    end
    helper_method :sections

    def set_section
      @section ||= begin
        sections.find { |section| section.permalink == params[:section_permalink] } || sections.first
      end
      raise ActiveRecord::RecordNotFound unless section.published?(true) || has_permission?('update', 'section')
      section
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
      flash[:notice] = notice
      redirect_to login_url(:return_to => request.url)
    end

    def return_from(action, options = {})
      URI.unescape(params[:return_to] || options[:default] || '/')
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



