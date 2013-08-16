class BaseController < ApplicationController
  class SectionRoutingError < ActionController::RoutingError; end
  helper :base, :resource, :content
  helper HasFilter::Helper
  helper TableBuilder

  include CacheableFlash
  include ContentHelper
  include ResourceHelper

  before_filter :set_site, :set_locale, :set_timezone, :set_cache_root
  attr_accessor :site, :section

  layout 'default'

  protected
    def set_site
      @site ||= Site.find_by_host!(request.host_with_port) # or raise "can not set site from host #{request.host_with_port}"
    end
    alias :site :set_site

    def set_section
      if @site
        @section ||= @site.sections.find_by_permalink(params[:section_permalink]) || @site.sections.root
      end

      unless @section.published?(true)
        raise ActiveRecord::RecordNotFound unless has_permission?('update', 'section')
      end
    end
    alias :section :set_section

    def set_locale
      # FIXME: really? what about "en-US", "sms" etc.?
      params[:locale] =~ /^[\w]{2}$/ or raise 'invalid locale' if params[:locale]
      I18n.locale = params[:locale] || I18n.default_locale
      # TODO raise something more meaningful
      I18n.locale.untaint
    end

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

    def perma_host
      @site ? @site.perma_host : ''
    end

    def page_cache_directory
      Rails.root + if Rails.env == 'test'
         Site.multi_sites_enabled ? '/tmp/cache/' + perma_host : '/tmp/cache'
       else
         # FIXME change this to
         # Site.multi_sites_enabled ? '/public/sites/' + perma_host : '/cache' ?
         Site.multi_sites_enabled ? '/public/cache/' + perma_host : '/public'
       end
    end
    
    def set_cache_root
      self.class.page_cache_directory = page_cache_directory.to_s
    end

    def skip_caching?
      @skip_caching or @article.try(:draft?)
    end

    def skip_caching!
      @skip_caching = true
    end
end



