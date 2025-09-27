require "rails_helper"

RSpec.describe "AuthenticateUser cookies" do
  it "remember_me! sets cookies and forget_me! clears them" do
    controller = BaseController.new
    request = ActionDispatch::TestRequest.create
    controller.set_request!(request)

    user = instance_double("User", id: 1, name: "Test User")
    allow(user).to receive(:anonymous?).and_return(false)
    allow(user).to receive(:assign_token!).with('remember me').and_return('token')

    allow(controller).to receive(:current_user).and_return(user)

    controller.send(:remember_me!)
    ck = controller.send(:cookies)
    expect(ck[:remember_me]).to be_present
    # set_user_cookie! writes uid/uname separately
    controller.send(:set_user_cookie!, user)
    ck = controller.send(:cookies)
    expect(ck[:uid]).to eq("1")
    expect(ck[:uname]).to eq("Test User")

    controller.send(:forget_me!)
    ck = controller.send(:cookies)
    expect(ck[:remember_me]).to be_nil
    expect(ck[:uid]).to be_nil
    expect(ck[:uname]).to be_nil
  end
end
