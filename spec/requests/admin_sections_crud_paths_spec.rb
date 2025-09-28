require "rails_helper"

RSpec.describe "Admin::Sections CRUD", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }

  before do
    host! site.host
    login_as_admin
  end

  it "creates successfully and supports create-another redirect" do
    permitted = ActionController::Parameters.new(section: { type: 'Page', title: 'T', permalink: 't' }, commit: 'Save and create another section').permit!
    expect {
      post admin_sections_path, params: permitted.to_h
    }.to change { site.sections.count }.by(1)
    expect(response).to redirect_to(new_admin_section_path)
  end

  it "handles create failure" do
    allow_any_instance_of(Section).to receive(:save).and_return(false)
    permitted = ActionController::Parameters.new(section: { type: 'Page', title: 'X', permalink: 'x' }).permit!
    post admin_sections_path, params: permitted.to_h
    expect(response).to have_http_status(:ok)
  end

  it "updates successfully and handles failure" do
    section = Page.create!(site: site, title: 'old', permalink: 'old')
    permitted = ActionController::Parameters.new(section: { title: 'new' }).permit!
    put admin_section_path(section), params: permitted.to_h
    expect(response.location).to match(%r{/admin/(sections|pages)/old/edit})

    allow_any_instance_of(Section).to receive(:update).and_return(false)
    permitted = ActionController::Parameters.new(section: { title: 'bad' }).permit!
    put admin_section_path(section), params: permitted.to_h
    expect(response).to have_http_status(:ok)
  end

  it "destroys successfully and handles failure" do
    section = Page.create!(site: site, title: 'gone', permalink: 'gone')
    delete admin_section_path(section)
    expect(response).to redirect_to(new_admin_section_path)

    section = Page.create!(site: site, title: 'stay', permalink: 'stay')
    allow_any_instance_of(Section).to receive(:destroy).and_return(false)
    delete admin_section_path(section)
    expect(response).to have_http_status(:ok)
  end
end
