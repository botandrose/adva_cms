class Admin::InstallController < ApplicationController
  helper :base

  before_filter :normalize_install_params, :only => :index
  before_filter :protect_install, :except => :confirmation

  layout "simple"
  renders_with_error_proc :below_field

  def index
    # TODO: can't we somehow encapsulate all this in a single model instead of juggling with 3 different models?
    params[:section] = params[:section]
    params[:section] ||= { :title => t(:'adva.sites.install.section_default') }
    params[:section][:type] ||= 'Page'

    @site = Site.new(params[:site])
    @section = @site.sections.build(params[:section])
    @user = User.new(params[:user])
    @user.name = @user.first_name_from_email
    @user.verified_at = Time.zone.now

    @article = @section.articles.build({
      title: t(:'adva.sites.install.section_default'),
      body: t(:'adva.sites.install.section_default'),
      author: @user,
      published_at: Time.zone.now,
    })

    if request.post?
      if @site.valid? && @section.valid? && @article.valid? && @user.valid?
        @site.save
        @user.roles << Rbac::Role.new(name: "superuser")
        authenticate_user(:email => @user.email, :password => @user.password)

        # default email for site
        @site.email ||= @user.email
        @site.save

        flash.now[:notice] = t(:'adva.sites.flash.install.success')
        render :action => :confirmation
      else
        models = [@site, @section, @article, @user].map { |model| model.class.name unless model.valid? }.compact
        flash.now[:error] = t(:'adva.sites.flash.install.failure', :models => models.join(', '))
      end
    end
  end

  protected

  def normalize_install_params
    params[:site] ||= {}
    params[:site].merge!(:host => request.host_with_port)
  end

  def protect_install
    if Site.first || User.first
      flash[:error] = t(:'adva.sites.flash.install.error_already_complete')
      redirect_to admin_sites_url
    end
  end
end
