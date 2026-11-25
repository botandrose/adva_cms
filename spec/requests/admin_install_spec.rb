require "rails_helper"

RSpec.describe "Admin install", type: :request do
  it "is not routed, so a GET is a routing miss rather than a missing controller" do
    get "/admin/install"

    expect(response).to have_http_status(:not_found)
    expect(request.env["action_dispatch.exception"].message).to eq(%(No route matches [GET] "/admin/install"))
  end

  it "is not routed, so a POST is a routing miss rather than a missing controller" do
    post "/admin/install"

    expect(response).to have_http_status(:not_found)
    expect(request.env["action_dispatch.exception"].message).to eq(%(No route matches [POST] "/admin/install"))
  end

  it "is not where the root redirects when there are no sites" do
    Site.delete_all

    get "/"

    expect(response).not_to redirect_to("/admin/install")
  end
end
