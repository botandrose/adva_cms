require "rails_helper"

RSpec.describe "Password", type: :request do
  let!(:site) { Site.find_by_host('site-with-pages.com') || Site.create!(name: 'site with pages', title: 'site with pages title', host: 'site-with-pages.com') }
  let!(:user) { User.find_by_email('a-user@example.com') || User.create!(first_name: 'a user', email: 'a-user@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

  it "renders new" do
    host! site.host
    get "/password/new"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="user[email]"')
  end

  it "create with known email redirects to edit" do
    host! site.host
    post "/password", params: { user: { email: user.email } }
    expect(response).to redirect_to(edit_password_url)
  end

  it "create with unknown email re-renders new" do
    host! site.host
    post "/password", params: { user: { email: 'nobody@example.com' } }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="user[email]"')
  end

  it "edit shows token+password fields when not logged in" do
    host! site.host
    get "/password/edit"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="token"')
    expect(response.body).to include('name="user[password]"')
  end

  it "update changes password for logged in user" do
    host! site.host
    post "/session", params: { user: { email: user.email, password: 'AAbbcc1122!!' } }
    expect(response).to be_redirect

    put "/password", params: { user: { password: 'NewPass1122!!' } }
    expect(response).to redirect_to("/")
  end

  it "update with invalid password renders form again" do
    host! site.host
    post "/session", params: { user: { email: user.email, password: 'AAbbcc1122!!' } }
    expect(response).to be_redirect

    put "/password", params: { user: { password: 'weak' } }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="user[password]"')
  end

  it "update without current user renders token form" do
    host! site.host

    put "/password", params: { user: { password: 'NewPass1122!!' }, token: 'invalid' }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="token"')
  end

  it "create redirects to edit form for valid user" do
    host! site.host
    post "/password", params: { user: { email: user.email } }

    expect(response).to redirect_to(edit_password_url)
  end

  it "update triggers password updated event on success" do
    host! site.host
    post "/session", params: { user: { email: user.email, password: 'AAbbcc1122!!' } }

    put "/password", params: { user: { password: 'NewPass1122!!' } }
    expect(response).to redirect_to("/")
  end

  it "create saves user after assigning token" do
    expect_any_instance_of(User).to receive(:save!)

    host! site.host
    post "/password", params: { user: { email: user.email } }
    expect(response).to redirect_to(edit_password_url)
  end
end

