require "rails_helper"

RSpec.describe "Admin::Users CRUD", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }

  before do
    host! site.host
    login_as_admin
  end

  it "creates a user and redirects to show" do
    expect {
      post admin_users_path, params: { user: { first_name: 'Bob', email: 'bob@example.com', password: 'AAbbcc1122!!' } }
    }.to change { User.count }.by(1)
    user = User.find_by_email!('bob@example.com')
    expect(response).to redirect_to(admin_user_url(user))
  end

  it "updates a user and redirects to show" do
    user = User.create!(first_name: 'Jane', email: 'jane@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
    put admin_user_path(user), params: { user: { first_name: 'Janet' } }
    expect(response).to redirect_to(admin_user_url(user))
    expect(user.reload.first_name).to eq('Janet')
  end

  it "destroys a user and redirects to index" do
    user = User.create!(first_name: 'Del', email: 'del@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
    delete admin_user_path(user)
    expect(response).to redirect_to(admin_users_url)
    expect(User.where(email: 'del@example.com')).to be_empty
  end
end

