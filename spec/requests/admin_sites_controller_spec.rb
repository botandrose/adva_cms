require "rails_helper"

RSpec.describe "Admin::SitesController", type: :request do
  let!(:admin_user) { User.create!(first_name: 'Admin', email: 'admin@example.com', password: 'AAbbcc1122!!', verified_at: Time.now, admin: true) }
  let!(:site) { Site.create!(name: 'Test Site', title: 'Test Site Title', host: 'test.example.com') }

  before do
    # Set up admin session
    host! site.host
    post "/session", params: { user: { email: admin_user.email, password: 'AAbbcc1122!!' } }
    expect(response).to redirect_to(root_url)
  end

  after { Site.multi_sites_enabled = nil }

  describe "GET /admin/sites" do
    context "when multi-sites is enabled" do
      before { Site.multi_sites_enabled = true }

      it "shows sites index" do
        get "/admin/sites"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Test Site')
      end
    end

    context "when multi-sites is disabled" do
      before { Site.multi_sites_enabled = false }

      it "redirects to the site show page" do
        get "/admin/sites"
        expect(response).to redirect_to(admin_site_url(Site.first))
      end
    end
  end

  describe "GET /admin/sites/:id" do
    it "shows site details" do
      get "/admin/sites/#{site.id}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Test Site Title')
    end
  end

  describe "GET /admin/sites/new" do
    context "when multi-sites is enabled" do
      before { Site.multi_sites_enabled = true }

      it "shows new site form" do
        get "/admin/sites/new"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<form')
      end
    end

    context "when multi-sites is disabled" do
      before { Site.multi_sites_enabled = false }

      it "shows multi-sites disabled message" do
        get "/admin/sites/new"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Multi-sites mode is not currently enabled')
      end
    end
  end

  describe "POST /admin/sites" do
    context "when multi-sites is enabled" do
      before { Site.multi_sites_enabled = true }

      context "with valid parameters" do
        let(:valid_params) do
          {
            site: {
              name: 'New Site',
              title: 'New Site Title',
              host: 'new.example.com',
              email: 'admin@example.com'
            },
            section: {
              title: 'Home',
              permalink: 'home',
              type: 'Page'
            }
          }
        end

        it "creates a new site" do
          expect {
            post "/admin/sites", params: valid_params
          }.to change(Site, :count).by(1)

          new_site = Site.last
          expect(new_site.name).to eq('New Site')
          expect(response).to redirect_to(admin_site_url(new_site))
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            site: { name: '', title: '', host: '' },
            section: { title: 'Home' }
          }
        end

        it "does not create a site and re-renders form" do
          expect {
            post "/admin/sites", params: invalid_params
          }.not_to change(Site, :count)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('<form')
        end
      end
    end
  end

  describe "GET /admin/sites/:id/edit" do
    it "shows edit form" do
      get "/admin/sites/#{site.id}/edit"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<form')
    end
  end

  describe "PATCH /admin/sites/:id" do
    context "with valid parameters" do
      let(:update_params) do
        { site: { name: 'Updated Site Name', title: 'Updated Title' } }
      end

      it "updates the site" do
        patch "/admin/sites/#{site.id}", params: update_params
        site.reload
        expect(site.name).to eq('Updated Site Name')
        expect(site.title).to eq('Updated Title')
        expect(response).to redirect_to(edit_admin_site_url)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        { site: { name: '', title: '' } }
      end

      it "does not update and re-renders edit form" do
        original_name = site.name
        patch "/admin/sites/#{site.id}", params: invalid_params
        site.reload
        expect(site.name).to eq(original_name)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<form')
      end
    end
  end

  describe "DELETE /admin/sites/:id" do
    context "when multi-sites is enabled" do
      before { Site.multi_sites_enabled = true }

      it "destroys the site" do
        site_to_delete = Site.create!(name: 'Delete Me', title: 'Delete Me', host: 'delete.example.com')

        expect {
          delete "/admin/sites/#{site_to_delete.id}"
        }.to change(Site, :count).by(-1)

        expect(response).to redirect_to(admin_sites_url)
      end
    end
  end
end