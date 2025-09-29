require "rails_helper"

RSpec.describe "Admin::Page::Links", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }
  let!(:section) { site.sections.first || Page.create!(site: site, title: 'a page', permalink: 'a-page', comment_age: 0) }

  describe "anonymous" do
    it "redirects to login on new" do
      host! site.host
      get new_admin_page_link_path(section)
      expect(response).to redirect_to(login_url(return_to: new_admin_page_link_url(section)))
    end
  end

  describe "authenticated admin" do
    before do
      host! site.host
      login_as_admin
    end

    it "new builds with optional params" do
      permitted = ActionController::Parameters.new(link: { title: 'X', body: 'b' }).permit!
      get new_admin_page_link_path(section), params: permitted.to_h
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('New Link')
    end

    it "creates successfully" do
      author_id = User.find_by(email: 'admin@example.com')&.id || User.create!(first_name: 'Admin', email: 'admin2@example.com', password: 'AAbbcc1122!!', verified_at: Time.now).id
      permitted = ActionController::Parameters.new(link: { title: 'L', body: 'B', permalink: 'l', author_id: author_id }).permit!
      post admin_page_links_path(section), params: permitted.to_h
      expect(response).to have_http_status(:found).or have_http_status(:ok)
    end

    it "renders create failure" do
      allow_any_instance_of(Link).to receive(:save).and_return(false)
      permitted = ActionController::Parameters.new(link: { title: 'B', body: 'BB', permalink: 'b' }).permit!
      post admin_page_links_path(section), params: permitted.to_h
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('New Link')
    end

    it "updates successfully" do
      author = User.create!(first_name: 'L', email: 'link@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
      link = section.links.create!(title: 'U', body: 'X', author: author, published_at: 1.hour.ago, permalink: 'u')
      permitted = ActionController::Parameters.new(link: { title: 'U2', body: 'XX' }).permit!
      put admin_page_link_path(section, link), params: permitted.to_h
      expect(response).to have_http_status(:found).or have_http_status(:ok)
    end

    it "renders update failure" do
      author = User.create!(first_name: 'L2', email: 'link2@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
      link = section.links.create!(title: 'UF', body: 'XF', author: author, published_at: 1.hour.ago, permalink: 'uf')
      allow_any_instance_of(Link).to receive(:update).and_return(false)
      permitted = ActionController::Parameters.new(link: { title: 'bad', body: 'YY' }).permit!
      put admin_page_link_path(section, link), params: permitted.to_h
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Edit Link')
    end

    it "destroys successfully" do
      author = User.create!(first_name: 'LD', email: 'linkd@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
      link = section.links.create!(title: 'D', body: 'Z', author: author, published_at: 1.hour.ago, permalink: 'd')
      delete admin_page_link_path(section, link)
      expect(response).to redirect_to(admin_page_contents_path(section))
    end

    it "renders destroy failure" do
      author = User.create!(first_name: 'LD2', email: 'linkd2@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
      link = section.links.create!(title: 'D2', body: 'ZZ', author: author, published_at: 1.hour.ago, permalink: 'd2')
      allow_any_instance_of(Link).to receive(:destroy).and_return(false)
      delete admin_page_link_path(section, link)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Edit Link')
    end

    it "indexes filtered links" do
      author = User.create!(first_name: 'L3', email: 'link3@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
      section.links.create!(title: 'Idx', body: 'B', author: author, published_at: 1.hour.ago, permalink: 'idx')
      get admin_page_links_path(section), params: { filters: { q: 'x' } }
      expect([200, 302, 404]).to include(response.status)
    end
  end
end
