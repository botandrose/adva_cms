require 'spec_helper'

class DummyScope
  attr_reader :assigns, :controller

  def initialize
    @assigns = {}
    @controller = Object.new
    @controller.instance_variable_set(:@current_user, 'user')
  end

  def resource_url(action, resource, options = {})
    "/#{options[:namespace]}/#{resource}-#{action}"
  end

  def normalize_resource_type(action, type, resource)
    :article
  end

  def url_for(arg)
    arg.is_a?(String) ? arg : "/generated"
  end

  def helper_value
    42
  end
end

RSpec.describe 'Menu::Builder' do
  it 'builds item url/id from resource and delegates url_for' do
    scope = DummyScope.new
    base = Menu::Base.new(:root)
    builder = Menu::Builder.new(base, scope)

    builder.namespace :admin
    builder.item :show, action: :show, resource: :post
    builder.item :custom, url: { controller: 'x', action: 'y' }

    show_item = base.children.find { |i| i.key == :show }
    custom_item = base.children.find { |i| i.key == :custom }

    expect(show_item.id).to eq(:show_article)
    expect(show_item.url).to eq('/admin/post-show')
    expect(custom_item.url).to eq('/generated')
  end

  it 'delegates undefined methods to the scope' do
    scope = DummyScope.new
    base = Menu::Base.new(:root)
    builder = Menu::Builder.new(base, scope)
    expect(builder.helper_value).to eq(42)
  end

  it 'calls super when method not found in scope or builder' do
    base = Menu::Base.new(:root)
    builder = Menu::Builder.new(base, nil)  # no scope

    expect { builder.undefined_method }.to raise_error(NoMethodError)
  end

  it 'assigns parents and activates via builder' do
    scope = DummyScope.new
    left = Menu::Menu.new(:left)
    right = Menu::Menu.new(:right)
    main = Menu::Group.new(:main)

    Menu::Builder.new(left)
    Menu::Builder.new(right)

    b = Menu::Builder.new(main, scope)
    b.parent(left)
    b.activates(right)

    expect(main.parent).to eq(left)
    expect(main.activates).to eq(right)
  end
end
