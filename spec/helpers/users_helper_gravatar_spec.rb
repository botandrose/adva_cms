require "rails_helper"

RSpec.describe UsersHelper, type: :helper do
  include UsersHelper

  it "gravatar_img builds an image tag and gravatar_url builds external url when not test env" do
    user = Struct.new(:email).new('user@example.com')
    # Simulate non-test env and presence of request
    allow(Rails).to receive_message_chain(:env, :test?).and_return(false)
    allow(helper).to receive(:request).and_return(double(host_with_port: 'example.test'))

    url = gravatar_url(user.email, 42)
    expect(url).to include('gravatar.com')
    img = gravatar_img(user)
    expect(img).to include('img')
  end
end

