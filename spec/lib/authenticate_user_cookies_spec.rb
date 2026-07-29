require "rails_helper"

# The credentials cookie itself belongs to authlogic and is asserted end-to-end
# in spec/requests/session_spec.rb. These are adva's own convenience cookies,
# which apps read to greet the user without hitting the database.
RSpec.describe "AuthenticateUser cookies" do
  let(:controller) do
    BaseController.new.tap do |c|
      c.set_request!(ActionDispatch::TestRequest.create)
    end
  end

  let(:user) do
    instance_double("User", id: 1, name: "Test User", anonymous?: false)
  end

  it "set_user_cookie! writes uid and uname" do
    controller.send(:set_user_cookie!, user)

    expect(controller.send(:cookies)[:uid]).to eq("1")
    expect(controller.send(:cookies)[:uname]).to eq("Test User")
  end

  it "set_user_cookie! writes nothing for an anonymous user" do
    controller.send(:set_user_cookie!, User.anonymous)

    expect(controller.send(:cookies)[:uid]).to be_nil
    expect(controller.send(:cookies)[:uname]).to be_nil
  end

  it "forget_me! clears them, along with any legacy remember_me cookie" do
    controller.send(:set_user_cookie!, user)

    controller.send(:forget_me!)

    expect(controller.send(:cookies)[:uid]).to be_nil
    expect(controller.send(:cookies)[:uname]).to be_nil
    expect(controller.send(:cookies)[:remember_me]).to be_nil
  end
end
