require "rails_helper"

RSpec.describe "UrlForReturning", type: :request do
  it "adds return_to when :return is true or :here" do
    controller = BaseController.new
    request = ActionDispatch::TestRequest.create
    def request.request_uri; "/current/path?x=1"; end
    controller.set_request!(request)

    url = controller.url_for(controller: "session", action: "new", only_path: true, return: true)
    expect(url).to include("return_to=%2Fcurrent%2Fpath%3Fx%3D1")

    url_here = controller.url_for(controller: "session", action: "new", only_path: true, return: :here)
    expect(url_here).to include("return_to=%2Fcurrent%2Fpath%3Fx%3D1")

    url_none = controller.url_for(controller: "session", action: "new", only_path: true)
    expect(url_none).not_to include("return_to=")
  end
end

