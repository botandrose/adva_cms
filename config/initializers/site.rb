class SiteFormBuilder < Adva::ExtensibleFormBuilder
  after(:site, :default_fields) do |f|
    render :partial => 'admin/sites/email_notifications', :locals => { :f => f }
  end
  after(:site, :default_fields) do |f|
    render :partial => 'admin/sites/meta_tags', :locals => { :f => f }
  end
end
