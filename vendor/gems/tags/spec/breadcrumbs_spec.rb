require 'spec_helper'

RSpec.describe 'Breadcrumbs' do
  it 'renders list items and marks the last as last' do
    items = [
      Menu::Item.new(:home, url: '/home'),
      Menu::Item.new(:section, url: '/home/section'),
      Menu::Item.new(:current, url: '/home/section/current')
    ]

    breadcrumbs = Breadcrumbs.new(items)
    html = breadcrumbs.render

    assert_html html, 'ul#breadcrumbs li a[href="/home"]', 'Home'
    assert_html html, 'ul#breadcrumbs li a[href="/home/section"]', 'Section'
    assert_html html, 'ul#breadcrumbs li.last', 'Current'
  end
end

