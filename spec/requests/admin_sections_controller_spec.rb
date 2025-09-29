require "rails_helper"

RSpec.describe "Admin::SectionsController", type: :request do
  let!(:site) { Site.create!(name: 'Admin Sections Site', title: 'Admin Sections', host: 'admin-sections.example.com') }
  let!(:admin_user) { User.create!(first_name: 'Admin', email: 'admin-sections@example.com', password: 'AAbbcc1122!!', verified_at: Time.now, admin: true) }

  before do
    host! site.host
    post "/session", params: { user: { email: admin_user.email, password: 'AAbbcc1122!!' } }
  end

  describe "GET /admin/sections" do
    it "lists sections" do
      Page.create!(site: site, title: 'S1', permalink: 's1', published_at: 1.hour.ago)
      get "/admin/sections"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/sections/new" do
    it "renders new with default type" do
      get "/admin/sections/new"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/sections" do
    it "creates section and redirects to articles index" do
      post "/admin/sections", params: { section: { title: 'Blog', permalink: 'blog', type: 'Page' } }
      section = Section.find_by(permalink: 'blog')
      expect(response).to redirect_to([:admin, section, :articles])
    end

    it "creates section and redirects to new when commit requests another" do
      post "/admin/sections", params: { section: { title: 'News', permalink: 'news', type: 'Page' }, commit: 'Save and create another section' }
      expect(response).to redirect_to([:new, :admin, :section])
    end

    it "renders new on validation failure" do
      post "/admin/sections", params: { section: { title: '', permalink: 'bad', type: 'Page' } }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('form').or include('Section')
    end
  end

  describe "GET /admin/sections/:id/edit" do
    it "renders edit" do
      section = Page.create!(site: site, title: 'Edit Me', permalink: 'edit-me', published_at: 1.hour.ago)
      get "/admin/sections/#{section.permalink}/edit"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PUT /admin/sections/:id" do
    let!(:section) { Page.create!(site: site, title: 'To Update', permalink: 'to-update', published_at: 1.hour.ago) }

    it "updates successfully and redirects back to edit" do
      put "/admin/sections/#{section.permalink}", params: { section: { title: 'Updated' } }
      expect(response).to redirect_to([:edit, :admin, section])
    end

    it "renders edit on validation failure" do
      put "/admin/sections/#{section.permalink}", params: { section: { title: '' } }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /admin/sections/:id" do
    it "destroys and redirects to new" do
      section = Page.create!(site: site, title: 'To Delete', permalink: 'to-delete', published_at: 1.hour.ago)
      delete "/admin/sections/#{section.permalink}"
      expect(response).to redirect_to([:new, :admin, :section])
    end

    it "renders edit with alert when destroy fails" do
      section = Page.create!(site: site, title: 'No Delete', permalink: 'no-delete', published_at: 1.hour.ago)
      allow_any_instance_of(Section).to receive(:destroy).and_return(false)
      delete "/admin/sections/#{section.permalink}"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PUT /admin/sections (update_all)" do
    it "reorders sections with and without parent, including left sibling and null normalization" do
      root1 = Page.create!(site: site, title: 'Root1', permalink: 'root1', published_at: 1.hour.ago)
      root2 = Page.create!(site: site, title: 'Root2', permalink: 'root2', published_at: 1.hour.ago)
      child = Page.create!(site: site, title: 'Child', permalink: 'child', published_at: 1.hour.ago)

      payload = {
        sections: {
          child.id.to_s => { parent_id: root1.id.to_s, left_id: root2.id.to_s, extra: { flag: 'null' } },
          root2.id.to_s => { parent_id: 'null', left_id: 'null' }
        }
      }

      put "/admin/sections", params: payload
      expect(response).to have_http_status(:ok)
    end
  end

  describe "normalize_params helper" do
    it "recursively converts 'null' to nil in nested hashes" do
      controller = Admin::SectionsController.new
      nested = { a: 'x', b: { c: 'null', d: { e: 'y' } }, f: 'null' }
      result = controller.send(:normalize_params, nested)
      expect(result[:b][:c]).to be_nil
      expect(result[:f]).to be_nil
      expect(result[:b][:d][:e]).to eq('y')
    end
  end
end
