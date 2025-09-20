require "rails_helper"

RSpec.describe "Admin::Sections authorized", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }

  before do
    host! site.host
    login_as_admin
  end

  it "renders index/new/edit for admin" do
    get admin_sections_path
    expect(response.code.to_i).to satisfy { |c| [200, 302].include?(c) }
    get new_admin_section_path
    expect(response.code.to_i).to satisfy { |c| [200, 302].include?(c) }
    section = Page.create!(site: site, title: 'old', permalink: 'old')
    get edit_admin_section_path(section)
    expect(response.code.to_i).to satisfy { |c| [200, 302].include?(c) }
  end
end
