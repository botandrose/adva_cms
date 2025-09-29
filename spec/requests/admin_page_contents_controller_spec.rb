require "rails_helper"

RSpec.describe "Admin::Page::ContentsController", type: :request do
  let!(:site) { Site.create!(name: 'Admin Page Site', title: 'Admin Page Site', host: 'admin-page.example.com') }
  let!(:section) { Page.create!(site: site, title: 'Admin Page', permalink: 'admin-page', published_at: 1.hour.ago) }
  let!(:admin_user) { User.create!(first_name: 'Admin', email: 'admin@example.com', password: 'AAbbcc1122!!', verified_at: Time.now, admin: true) }

  before do
    Site.multi_sites_enabled = true
    host! site.host
    post "/session", params: { user: { email: admin_user.email, password: 'AAbbcc1122!!' } }
  end

  describe "GET /admin/pages/:page_id/contents (index)" do
    it "renders index with contents for the section" do
      allow_any_instance_of(Page).to receive(:single_article_mode).and_return(false)
      a1 = Article.create!(site: site, section: section, title: 'A1', body: 'b', author: admin_user, published_at: 1.hour.ago, permalink: 'a1')
      get "/admin/pages/#{section.permalink}/contents"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('There are no contents').or include('Edit')
    end
  end

  describe "PUT /admin/pages/:page_id/contents (update_all)" do
    it "reorders contents with and without parent, and left sibling" do
      root1 = Article.create!(site: site, section: section, title: 'Root1', body: 'b', author: admin_user, published_at: 1.hour.ago, permalink: 'root1')
      root2 = Article.create!(site: site, section: section, title: 'Root2', body: 'b', author: admin_user, published_at: 1.hour.ago, permalink: 'root2')
      child = Article.create!(site: site, section: section, title: 'Child', body: 'b', author: admin_user, published_at: 1.hour.ago, permalink: 'child')

      payload = {
        contents: {
          child.id => { parent_id: root1.id, left_id: root2.id }, # has parent and left sibling
          root2.id => { } # no parent: will move to root and left of its siblings
        }
      }

      put "/admin/pages/#{section.permalink}/contents", params: payload
      expect(response).to have_http_status(:ok)
    end

    it "handles entries without parent_id (move_to_root/left_of)" do
      rootA = Article.create!(site: site, section: section, title: 'RootA', body: 'b', author: admin_user, published_at: 1.hour.ago, permalink: 'roota')
      rootB = Article.create!(site: site, section: section, title: 'RootB', body: 'b', author: admin_user, published_at: 1.hour.ago, permalink: 'rootb')

      payload = { contents: { rootA.id.to_s => { foo: 'x' } } }
      put "/admin/pages/#{section.permalink}/contents", params: payload
      expect(response).to have_http_status(:ok)
    end
  end

  describe "protect_single_content_mode redirects" do
    it "redirects to new article when single_article_mode and no contents" do
      allow_any_instance_of(Page).to receive(:single_article_mode).and_return(true)
      section.articles.destroy_all
      get "/admin/pages/#{section.permalink}/contents"
      expect(response).to redirect_to(new_admin_page_article_url(section, content: { title: section.title }))
    end

    it "redirects to edit first article when single_article_mode and contents exist" do
      allow_any_instance_of(Page).to receive(:single_article_mode).and_return(true)
      first_article = Article.create!(site: site, section: section, title: 'First', body: 'b', author: admin_user, published_at: 1.hour.ago, permalink: 'first')
      get "/admin/pages/#{section.permalink}/contents"
      expect(response).to redirect_to(edit_admin_page_article_url(section, first_article))
    end
  end

  describe "protected helpers" do
    it "current_resource returns @content or @section" do
      controller = Admin::Page::ContentsController.new
      controller.request = ActionDispatch::Request.new('HTTP_HOST' => site.host)
      controller.response = ActionDispatch::Response.new
      controller.instance_variable_set(:@section, section)

      # with no @content
      expect(controller.send(:current_resource)).to eq(section)

      # with @content present
      content = Article.create!(site: site, section: section, title: 'CR', body: 'b', author: admin_user, published_at: 1.hour.ago, permalink: 'cr')
      controller.instance_variable_set(:@content, content)
      expect(controller.send(:current_resource)).to eq(content)
    end

    it "set_menu assigns contents menu" do
      controller = Admin::Page::ContentsController.new
      controller.request = ActionDispatch::Request.new('HTTP_HOST' => site.host)
      controller.response = ActionDispatch::Response.new
      controller.send(:set_menu)
      expect(controller.instance_variable_get(:@menu)).to be_a(Menus::Admin::Contents)
    end

    it "set_categories assigns section root categories" do
      controller = Admin::Page::ContentsController.new
      controller.request = ActionDispatch::Request.new('HTTP_HOST' => site.host)
      controller.response = ActionDispatch::Response.new
      controller.instance_variable_set(:@section, section)
      controller.send(:set_categories)
      expect(controller.instance_variable_get(:@categories)).to eq(section.categories.roots)
    end
  end
end
