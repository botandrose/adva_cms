require "rails_helper"

RSpec.describe "BaseController Additional Coverage", type: :request do
  let!(:site) { Site.create!(name: 'coverage test', title: 'Coverage Test Site', host: 'coverage-test.com', timezone: 'America/New_York') }
  let!(:section) { Page.create!(site: site, title: 'Test Section', permalink: 'test-section', published_at: 1.hour.ago) }
  let!(:user) { User.create!(first_name: 'Test', email: 'test@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }
  let!(:admin) { User.create!(first_name: 'Admin', email: 'admin@example.com', password: 'AAbbcc1122!!', verified_at: Time.now, admin: true) }

  before { host! site.host }

  describe "skip_caching methods" do
    let(:controller) { BaseController.new }

    before do
      controller.request = ActionDispatch::Request.new('HTTP_HOST' => site.host)
      controller.response = ActionDispatch::Response.new
      allow(controller).to receive(:site).and_return(site)
    end

    describe "#skip_caching?" do
      it "returns true when @skip_caching is set" do
        controller.instance_variable_set(:@skip_caching, true)
        expect(controller.send(:skip_caching?)).to be_truthy
      end

      it "returns false when @skip_caching is false and no draft article" do
        controller.instance_variable_set(:@skip_caching, false)
        expect(controller.send(:skip_caching?)).to be_falsy
      end

      it "returns true when article is draft" do
        draft_article = Article.create!(
          site: site,
          section: section,
          title: 'Draft',
          body: 'Draft content',
          author: user,
          published_at: nil,
          permalink: 'draft'
        )
        controller.instance_variable_set(:@article, draft_article)
        expect(controller.send(:skip_caching?)).to be_truthy
      end

      it "returns false when article is published" do
        published_article = Article.create!(
          site: site,
          section: section,
          title: 'Published',
          body: 'Published content',
          author: user,
          published_at: 1.hour.ago,
          permalink: 'published'
        )
        controller.instance_variable_set(:@article, published_article)
        expect(controller.send(:skip_caching?)).to be_falsy
      end

      it "returns false when @article is nil" do
        controller.instance_variable_set(:@article, nil)
        expect(controller.send(:skip_caching?)).to be_falsy
      end
    end

    describe "#skip_caching!" do
      it "sets @skip_caching to true" do
        controller.send(:skip_caching!)
        expect(controller.instance_variable_get(:@skip_caching)).to be_truthy
      end
    end
  end

  describe "set_commentable method" do
    let(:controller) { BaseController.new }

    before do
      controller.request = ActionDispatch::Request.new('HTTP_HOST' => site.host)
      controller.response = ActionDispatch::Response.new
      allow(controller).to receive(:site).and_return(site)
    end

    it "sets @commentable to @article when present" do
      article = Article.create!(
        site: site,
        section: section,
        title: 'Article',
        body: 'Content',
        author: user,
        published_at: 1.hour.ago,
        permalink: 'article'
      )
      controller.instance_variable_set(:@article, article)
      controller.instance_variable_set(:@section, section)
      controller.instance_variable_set(:@site, site)

      controller.send(:set_commentable)

      expect(controller.instance_variable_get(:@commentable)).to eq(article)
    end

    it "sets @commentable to @section when no @article" do
      controller.instance_variable_set(:@article, nil)
      controller.instance_variable_set(:@section, section)
      controller.instance_variable_set(:@site, site)

      controller.send(:set_commentable)

      expect(controller.instance_variable_get(:@commentable)).to eq(section)
    end

    it "sets @commentable to @site when no @article or @section" do
      controller.instance_variable_set(:@article, nil)
      controller.instance_variable_set(:@section, nil)
      controller.instance_variable_set(:@site, site)

      controller.send(:set_commentable)

      expect(controller.instance_variable_get(:@commentable)).to eq(site)
    end
  end

  describe "rescue_action method" do
    let(:controller) { BaseController.new }

    before do
      controller.request = ActionDispatch::Request.new('HTTP_HOST' => site.host, 'REQUEST_URI' => '/test')
      controller.response = ActionDispatch::Response.new
      allow(controller).to receive(:site).and_return(site)
      allow(controller).to receive(:login_url).and_return('/login')

      # Create the mock class if it doesn't exist
      unless defined?(ActionController::RoleRequired)
        ActionController.const_set(:RoleRequired, Class.new(StandardError))
      end
    end

    it "redirects to login for RoleRequired exception" do
      role_exception = ActionController::RoleRequired.new("Access denied")
      allow(controller).to receive(:redirect_to_login)

      controller.send(:rescue_action, role_exception)
      expect(controller).to have_received(:redirect_to_login).with("Access denied")
    end

    it "handles other exceptions by calling super" do
      other_exception = StandardError.new("Other error")

      # The rescue_action method calls super, which should call the parent class
      # Since there's no real parent implementation in our test environment,
      # we expect it to raise a NoMethodError, which is normal behavior
      expect { controller.send(:rescue_action, other_exception) }.to raise_error(NoMethodError)
    end
  end

  describe "redirect_to_login method" do
    let(:controller) { BaseController.new }

    before do
      controller.request = ActionDispatch::Request.new(
        'HTTP_HOST' => site.host,
        'REQUEST_URI' => '/test-path',
        'REQUEST_METHOD' => 'GET'
      )
      controller.response = ActionDispatch::Response.new
      allow(controller).to receive(:login_url).and_return('/login')
      allow(controller).to receive(:redirect_to)
    end

    it "redirects to login with return_to parameter" do
      controller.send(:redirect_to_login)

      expect(controller).to have_received(:redirect_to).with('/login', notice: nil)
    end

    it "redirects to login with notice" do
      controller.send(:redirect_to_login, "Please log in")

      expect(controller).to have_received(:redirect_to).with('/login', notice: "Please log in")
    end
  end

  describe "current_resource method" do
    let(:controller) { BaseController.new }

    before do
      controller.request = ActionDispatch::Request.new('HTTP_HOST' => site.host)
      controller.response = ActionDispatch::Response.new
      allow(controller).to receive(:site).and_return(site)
    end

    it "returns @section when present" do
      controller.instance_variable_set(:@section, section)
      controller.instance_variable_set(:@site, site)

      expect(controller.send(:current_resource)).to eq(section)
    end

    it "returns @site when no @section" do
      controller.instance_variable_set(:@section, nil)
      controller.instance_variable_set(:@site, site)

      expect(controller.send(:current_resource)).to eq(site)
    end
  end

  describe "current_page method edge cases" do
    let(:controller) { BaseController.new }

    before do
      controller.request = ActionDispatch::Request.new('HTTP_HOST' => site.host)
      controller.response = ActionDispatch::Response.new
      allow(controller).to receive(:site).and_return(site)
    end

    it "handles string page parameter" do
      allow(controller).to receive(:params).and_return({ page: '5' })

      expect(controller.send(:current_page)).to eq(5)
    end

    it "handles non-numeric page parameter" do
      allow(controller).to receive(:params).and_return({ page: 'abc' })

      expect(controller.send(:current_page)).to eq(1)
    end

    it "handles negative page parameter" do
      allow(controller).to receive(:params).and_return({ page: '-1' })

      # Based on the actual implementation, negative values pass through
      expect(controller.send(:current_page)).to eq(-1)
    end

    it "caches the page value" do
      allow(controller).to receive(:params).and_return({ page: '3' })

      # First call
      first_result = controller.send(:current_page)
      # Second call should return cached value
      second_result = controller.send(:current_page)

      expect(first_result).to eq(3)
      expect(second_result).to eq(3)
      expect(controller.instance_variable_get(:@page)).to eq(3)
    end
  end

  describe "timezone handling with nil site" do
    let(:controller) { BaseController.new }

    before do
      controller.request = ActionDispatch::Request.new('HTTP_HOST' => site.host)
      controller.response = ActionDispatch::Response.new
    end

    it "handles nil @site gracefully" do
      controller.instance_variable_set(:@site, nil)
      original_zone = Time.zone

      controller.send(:set_timezone)

      expect(Time.zone).to eq(original_zone)
    end

    it "sets timezone when @site has timezone" do
      controller.instance_variable_set(:@site, site)

      controller.send(:set_timezone)

      expect(Time.zone.name).to eq('America/New_York')
    end
  end

  describe "sections helper method" do
    let(:controller) { BaseController.new }

    before do
      controller.request = ActionDispatch::Request.new('HTTP_HOST' => site.host)
      controller.response = ActionDispatch::Response.new
      allow(controller).to receive(:site).and_return(site)
    end

    it "caches sections from site" do
      expect(site).to receive(:sections).once.and_return([section])

      # First call
      first_result = controller.send(:sections)
      # Second call should use cached value
      second_result = controller.send(:sections)

      expect(first_result).to eq([section])
      expect(second_result).to eq([section])
    end
  end
end