require "rails_helper"

RSpec.describe "Admin::BaseController additional coverage", type: :request do
  let!(:site) { Site.create!(name: 'Admin Base Coverage', title: 'Admin Base Coverage', host: 'admin-base-coverage.test', timezone: 'UTC') }
  let!(:section) { Page.create!(site: site, title: 'Admin Section', permalink: 'admin-section', published_at: 1.hour.ago) }

  describe "#current_resource fallback order" do
    it "prefers @section, then @site, then Site.new" do
      controller = Admin::BaseController.new
      controller.request = ActionDispatch::Request.new('HTTP_HOST' => site.host)
      controller.response = ActionDispatch::Response.new

      # 1) With @section present
      controller.instance_variable_set(:@section, section)
      controller.instance_variable_set(:@site, site)
      expect(controller.send(:current_resource)).to eq(section)

      # 2) With only @site present
      controller.remove_instance_variable(:@section)
      controller.instance_variable_set(:@site, site)
      expect(controller.send(:current_resource)).to eq(site)

      # 3) With neither present falls back to Site.new
      controller.remove_instance_variable(:@site)
      resource = controller.send(:current_resource)
      expect(resource).to be_a(Site)
      expect(resource).to be_new_record
    end
  end

  describe "#current_page caching and parsing" do
    it "parses page param and memoizes the value" do
      controller = Admin::BaseController.new
      controller.request = ActionDispatch::Request.new('HTTP_HOST' => site.host)
      controller.response = ActionDispatch::Response.new

      allow(controller).to receive(:params).and_return({ page: '4' }.with_indifferent_access)

      first = controller.send(:current_page)
      second = controller.send(:current_page)

      expect(first).to eq(4)
      expect(second).to eq(4)
      expect(controller.instance_variable_get(:@page)).to eq(4)

      # Change params to ensure memoized value is used
      allow(controller).to receive(:params).and_return({ page: '2' }.with_indifferent_access)
      expect(controller.send(:current_page)).to eq(4)
    end
  end

  describe "#update_role_context! triggers section resolution" do
    it "calls set_section when section_id present and @section is nil" do
      controller = Admin::BaseController.new
      controller.request = ActionDispatch::Request.new('HTTP_HOST' => site.host)
      controller.response = ActionDispatch::Response.new

      # Provide the site expected by set_section and seed params with section_id
      controller.instance_variable_set(:@site, site)
      params_hash = { section_id: section.permalink }.with_indifferent_access
      allow(controller).to receive(:params).and_return(params_hash)

      expect(controller.instance_variable_defined?(:@section)).to be_falsey
      controller.send(:update_role_context!, params_hash)
      expect(controller.instance_variable_get(:@section)).to eq(section)
    end
  end
end

