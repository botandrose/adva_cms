require 'spec_helper'

module MenuTest
  class TopMenu < Menu::Group
    define :id => 'top', :class => 'top' do |g|
      breadcrumb :site, :content => '<a href="/path/to/site">Site</a>'

      g.menu :left, :class => 'left' do |m|
        m.item :sections, :url => '/path/to/sections'
      end

      g.menu :right, :class => 'right' do |m|
        m.item :settings, :url => '/path/to/settings'
      end
    end
  end

  class BlogMenu < Menu::Group
    define do |g|
      g.id :main
      g.parent TopMenu.new.build.root[:'left.sections']

      g.menu :left do |m|
        m.item :articles, :url => '/path/to/articles'
        m.item :categories, :url => '/path/to/categories'
      end

      g.menu :right do |m|
        m.activates object.parent[:'left.articles']
        m.item :new, :url => '/path/to/articles/new'
        m.item :edit, :url => '/path/to/articles/edit'
      end
    end
  end

  RSpec.describe 'MenuDefinition' do
    before do
      @top = BlogMenu.new.build.root
    end

    it 'defers the id from the class name' do
      expect(@top.id).to eq(:top)
    end

    it 'provides hash style access' do
      expect(@top[:left]).not_to be_nil
    end

    it 'provides hash style access w/ multiple keys' do
      expect(@top[:left, :sections, :main]).not_to be_nil
    end

    it 'provides hash style access w/ dot separated keys' do
      expect(@top[:'left.sections.main']).not_to be_nil
    end

    it 'builds and applies definitions' do
      sections = @top[:'left.sections']
      main = sections[:main]
      articles = main[:'left.articles']

      expect(@top.id).to eq(:top)
      expect(@top[:left].id).to eq(:left)
      expect(sections.id).to eq(:sections)
      expect(main.id).to eq(:main)
      expect(main[:left].id).to eq(:left)
      expect(main[:right].id).to eq(:right)
      expect(articles.id).to eq(:articles)
      expect(main[:'right.new'].id).to eq(:new)

      expect(@top[:left].object_id).to eq(@top[:left].parent.children.first.object_id)
      expect(main.object_id).to eq(main.parent.children.first.object_id)
      expect(main[:left].object_id).to eq(main[:left].parent.children.first.object_id)
      expect(main[:right].object_id).to eq(main[:right].parent.children[1].object_id)

      expect(@top).to be_a(Menu::Group)
      expect(main).to be_a(Menu::Group)

      expect(@top[:left].class).to eq(Menu::Menu)
      expect(main[:left].class).to eq(Menu::Menu)
      expect(main[:right].class).to eq(Menu::Menu)

      expect(@top[:left].children.first.class).to eq(Menu::Item)
      expect(main[:left].children.first.class).to eq(Menu::Item)
      expect(main[:right].children.first.class).to eq(Menu::Item)
    end

    it 'finds an immediate child' do
      expect(@top.find(:left)).not_to be_nil
      expect(@top[:left].find(:sections)).not_to be_nil
      expect(@top[:'left.sections'].find(:main)).not_to be_nil
      expect(@top[:'left.sections.main'].find(:left)).not_to be_nil
    end

    it "finds a children's child" do
      expect(@top.find(:sections)).not_to be_nil
      expect(@top[:left].find(:main)).not_to be_nil
      expect(@top[:'left.sections'].find(:left)).not_to be_nil
      expect(@top[:'left.sections.main'].find(:articles)).not_to be_nil
    end

    it "finds grand-children's children" do
      expect(@top.find(:new)).not_to be_nil
    end

    it 'returns topmost node as root' do
      expect(@top[:"left.sections.main.right.new"].root.id).to eq(:top)
    end

    it 'activates the expected nodes' do
      @top.activate('/path/to/articles/edit')

      expect(@top.active).to be_truthy
      expect(@top[:left].active).to be_truthy
      expect(@top[:'left.sections'].active).to be_truthy
      expect(@top[:'left.sections.main'].active).to be_truthy
      expect(@top[:'left.sections.main.left'].active).to be_truthy
      expect(@top[:'left.sections.main.left.articles'].active).to be_truthy
      expect(@top[:'left.sections.main.right'].active).to be_truthy
      expect(@top[:'left.sections.main.right.edit'].active).to be_truthy

      expect(@top[:right].active).to eq(false)
      expect(@top[:'right.settings'].active).to eq(false)
      expect(@top[:'left.sections.main.left.categories'].active).to eq(false)
      expect(@top[:'left.sections.main.right.new'].active).to eq(false)
    end

    it 'can access the active node from root' do
      @top.activate('/path/to/articles/edit')
      expect(@top.active.id).to eq(:edit)
    end

    it 'provides breadcrumbs' do
      @top.activate('/path/to/articles/edit')
      expect(@top.active.breadcrumbs.map(&:id)).to eq([:site, :sections, :articles, :edit])

      breadcrumbs = @top.active.breadcrumbs.map(&:content).join
      assert_html breadcrumbs, 'a[href="/path/to/site"]'
      assert_html breadcrumbs, 'a[href="/path/to/sections"]'
      assert_html breadcrumbs, 'a[href="/path/to/articles"]'
      assert_html breadcrumbs, 'a[href="/path/to/articles/edit"]'
    end
  end

  RSpec.describe 'MenuItem' do
    it 'renders a span tag if no url is set' do
      assert_html Menu::Item.new('foo').render, 'li span', 'foo'
    end

    it 'renders an a tag if url is set' do
      assert_html Menu::Item.new('foo', :url => 'bar').render, 'li a[href="bar"]', 'foo'
    end

    it 'uses a text option if given' do
      item = Menu::Item.new('foo', :text => 'foo text')
      assert_html item.render, 'span', 'foo text'
    end
  end

  RSpec.describe 'Menu' do
    it 'renders a ul tag' do
      menu = Menu::Menu.new
      menu.children << Menu::Item.new('foo')
      assert_html menu.render(:class => 'menu', :id => 'menu'), 'ul[id="menu"][class="menu"] li span', 'foo'
    end

    it 'renders id and class options' do
      menu = TopMenu.new.build
      assert_html menu.render, 'top_menu[id="top"][class="top"] ul[class="left"]'
      assert_html menu.render(:id => 'top-2', :class => 'top-2'), 'top_menu[id="top-2"][class="top-2"] ul[class="left"]'
    end
  end
end