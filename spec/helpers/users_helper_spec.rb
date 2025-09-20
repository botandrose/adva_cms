require "rails_helper"

RSpec.describe UsersHelper, type: :helper do
  include UsersHelper

  DummyUser = Struct.new(:name, :email, :homepage) do
    def is_a?(k); k == User || super; end
  end

  it "who returns You for current user name" do
    me = DummyUser.new('John', 'john@example.com', nil)
    helper.define_singleton_method(:current_user) { me }
    expect(helper.who('John')).to eq('You')
    expect(helper.who(me)).to eq('You')
  end

  it "gravatar_url returns default in test env and when email blank" do
    expect(gravatar_url(nil)).to eq('/assets/adva_cms/avatar.gif')
    expect(gravatar_url('')).to eq('/assets/adva_cms/avatar.gif')
  end

  it "link_to_author builds link with optional email" do
    resource = Struct.new(:author_name, :author_homepage, :author_email)
                .new('Alice', 'http://example.com', 'alice@example.com')
    helper.define_singleton_method(:h) { |s| s }
    html = helper.link_to_author(resource)
    expect(html).to include('Alice')
    expect(html).to include('http://example.com')
    html = helper.link_to_author(resource, include_email: true)
    expect(html).to include('alice@example.com')
  end
end
