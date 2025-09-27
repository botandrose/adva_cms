require 'spec_helper'

# Mock section class for testing
class MockSection
  attr_reader :title, :level

  def initialize(title, level, new_record = false)
    @title = title
    @level = level
    @new_record = new_record
  end

  def new_record?
    @new_record
  end
end

RSpec.describe 'Menu::SectionsMenu' do
  # Test lines 139-141: initialize method
  it 'initializes with sections array' do
    menu = Menu::SectionsMenu.new(:test)
    expect(menu.sections).to eq([])
  end

  # Test lines 144-148: populate method
  it 'populates sections from scope' do
    menu = Menu::SectionsMenu.new(:test)
    sections_data = [
      MockSection.new('Home', 1),
      MockSection.new('Draft', 1, true)  # new_record
    ]

    # Create a simple scope mock
    scope = Object.new
    scope.instance_variable_set(:@sections_data, sections_data)

    # Set the populate proc
    menu.instance_variable_set(:@options, { populate: proc { @sections_data } })

    # Mock url_for method on scope
    def scope.url_for(path)
      "/admin/sections/#{path[1].title.downcase}/contents"
    end

    menu.populate(scope)

    expect(menu.sections.length).to eq(1)  # excludes new_record
    expect(menu.sections.first.id).to eq('Home')
  end

  # Test line 151: breadcrumbs method
  it 'returns breadcrumbs with item and active section' do
    menu = Menu::SectionsMenu.new(:test, text: 'Test', url: '/test')

    # Create a mock activates object with breadcrumbs method
    activates_mock = Object.new
    def activates_mock.breadcrumbs
      [Menu::Item.new(:parent, url: '/parent')]
    end
    menu.activates = activates_mock

    # Create a section and mark it as active
    section = Menu::Base.new('Section1', level: 1, url: '/sections/1')
    section.active = menu
    menu.instance_variable_set(:@sections, [section])

    breadcrumbs = menu.breadcrumbs
    expect(breadcrumbs.length).to eq(3)  # activates.breadcrumbs + item + active_section
  end

  # Test lines 154-158: activate method
  it 'activates sections based on path pattern' do
    menu = Menu::SectionsMenu.new(:test)
    section = Menu::Base.new('Section1', level: 1, url: '/admin/sections/1/contents')
    menu.instance_variable_set(:@sections, [section])

    # Mock starts_with? method on url
    url = section.url
    def url.starts_with?(path)
      self.include?(path)
    end

    menu.activate('/admin/sections/1/pages/123')

    expect(section.active).to eq(menu)
  end

  # Test line 161: item method
  it 'creates an item with menu attributes' do
    menu = Menu::SectionsMenu.new(:test, text: 'Test Text', url: '/test')
    menu.instance_variable_set(:@content, 'Test Content')

    item = menu.item

    expect(item).to be_a(Menu::Item)
    expect(item.key).to eq(:test)
  end

  # Test lines 165-166: active_section method
  it 'returns active section as item' do
    menu = Menu::SectionsMenu.new(:test, url: '/test')
    section = Menu::Base.new('Section1', level: 1, url: '/sections/1')
    section.active = menu
    menu.instance_variable_set(:@sections, [section])

    active_section = menu.active_section

    expect(active_section).to be_a(Menu::Item)
    expect(active_section.key).to eq(:section)
  end

  # Test lines 170-177: content method
  it 'renders content with sections menu' do
    menu = Menu::SectionsMenu.new(:test, text: 'Test')
    section = Menu::Base.new('Home', level: 1, url: '/sections/1')
    section.options = { class: 'test-class' }
    menu.instance_variable_set(:@sections, [section])

    content = menu.content

    expect(content).to include('sections_menu')
    expect(content).to include('/sections/1')
    expect(content).to include('level_1')
  end
end