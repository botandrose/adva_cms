require 'spec_helper'

RSpec.describe 'Menu::Base extras' do
  it 'raises on missing key in []' do
    menu = Menu::Menu.new(:root)
    expect { menu[:missing] }.to raise_error(/can not find item/)
  end

  it 'propagates namespace from parent' do
    parent = Menu::Menu.new(:parent)
    Menu::Builder.new(parent).namespace :admin
    child = Menu::Menu.new(:child)
    parent.children << child
    expect(child.namespace).to eq(:admin)
  end

  it 'computes activation_path and resets' do
    root = Menu::Menu.new(:root)
    left = Menu::Menu.new(:left)
    item = Menu::Item.new(:show, url: '/foo')
    root.children << left
    left.children << item

    root.activate('/foo/pages/123?x=1')
    expect(item.active).to eq(item)
    expect(item.activation_path.map(&:id)).to eq([:show, :left, :root])

    root.reset
    expect([root.active, left.active, item.active]).to all(be(false))
  end

  it 'build? reflects definitions built state' do
    class BuildMenu < Menu::Menu
      define { |m| m.item :a, url: '/a' }
    end

    menu = BuildMenu.new
    expect(menu.build?).to be(true)
    menu.build
    expect(menu.build?).to be(false)
  end
end
