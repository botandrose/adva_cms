require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'test_helper' ))

module IntegrationTests
  class AdminThemeFilesTest < ActionController::IntegrationTest
    include ThemeTestHelper
    
    def setup
      super
      @site = use_site! 'site with sections'
      @theme = @site.themes.find_by_theme_id('a-theme')
      @theme.activate!
      @admin_theme_show_page = "/admin/sites/#{@site.id}/themes/#{@theme.id}"
    end

    test "Admin creates a bunch of theme files, updates and deletes them" do
      login_as_superuser
      visits_theme_show_page
      
      # template
      creates_a_new_theme_file :filename => 'layouts/default.html.erb', :data => 'the theme default layout'
      check_homepage 'the theme default layout'
      
      # javascript
      creates_a_new_theme_file :filename => 'effects.js', :data => 'alert("booom!")'
      updates_the_theme_file   :data => 'alert("booom boom boom!")'

      # stylesheet
      creates_a_new_theme_file :filename => 'styles.css', :data => 'body { background-color: red }'
      updates_the_theme_file   :data => 'body { background-color: yellow }'

      # image
      creates_a_new_theme_file :filename => 'the-logo.png', :data => image_fixture
      updates_the_theme_file   :filename => 'the-ueber-logo.png'
      
      # update the layout
      click_link 'layouts/default.html.erb'

      updates_the_theme_file   :data => <<-eoc
        <%= theme_javascript_include_tag 'a-theme', :all, :cache => true %>
        <%= theme_stylesheet_link_tag 'a-theme', 'styles' %>
        <%= theme_image_tag 'a-theme', 'the-ueber-logo' %>
        the updated theme default layout
      eoc

      check_homepage '<script src="/themes/a-theme/javascripts/all.js" type="text/javascript"></script>',
                     '<link href="/themes/a-theme/stylesheets/styles.css" media="screen" rel="stylesheet" type="text/css" />',
                     '<img alt="The-ueber-logo" src="/themes/a-theme/images/the-ueber-logo" />',
                     'the updated theme default layout'

      deletes_the_theme_file 'layouts/default.html.erb'
      deletes_the_theme_file 'effects.js'
      deletes_the_theme_file 'styles.css'
      deletes_the_theme_file 'the-ueber-logo.png'
    end
    
    def check_homepage(*strings)
      @backbutton = request.path
      visit '/'
      strings.each { |str| has_text str }
      visit @backbutton
    end

    def visits_theme_show_page
      visit @admin_theme_show_page
      assert_template "admin/themes/show"
    end

    def creates_a_new_theme_file(attributes)
      click_link 'Create a new file'
      assert_template "admin/theme_files/new"

      attributes.each do |name, value|
        fill_in name, :with => value
      end
      click_button 'Save'
      assert_template "admin/theme_files/show"
    end

    def updates_the_theme_file(attributes)
      attributes.each do |name, value|
        fill_in name, :with => value
      end
      click_button 'Save'
      assert_template "admin/theme_files/show"
    end
    
    def deletes_the_theme_file(name)
      click_link name
      click_link 'Delete theme file'
      assert_template "admin/themes/show"
    end
  end
end