require "rails_helper"

RSpec.describe "Admin::Users failure flows", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }

  before do
    host! site.host
    login_as_admin
  end

  it "renders on create failure" do
    allow_any_instance_of(User).to receive(:save).and_return(false)
    post admin_users_path, params: { user: { first_name: 'X', email: 'x@e.c', password: 'AAbbcc1122!!' } }
    expect(response).to have_http_status(:ok)
  end

  it "renders on update and destroy failure" do
    user = User.create!(first_name: 'U', email: 'u@e.co', password: 'AAbbcc1122!!', verified_at: Time.now)
    allow_any_instance_of(User).to receive(:update).and_return(false)
    put admin_user_path(user), params: { user: { first_name: 'Z' } }
    expect(response).to have_http_status(:ok)

    allow_any_instance_of(User).to receive(:destroy).and_return(false)
    delete admin_user_path(user)
    expect(response).to have_http_status(:ok)
  end
end
