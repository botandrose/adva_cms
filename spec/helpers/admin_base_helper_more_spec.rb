require "rails_helper"
require "timecop"

RSpec.describe Admin::BaseHelper, type: :helper do
  include Admin::BaseHelper

  it "save_or_cancel_links builds buttons and optional cancel" do
    builder = double("builder")
    expect(builder).to receive(:buttons).and_yield
    html = save_or_cancel_links(builder, cancel_url: "/x")
    expect(html).to include("commit")
    expect(html).to include("Cancel")
  end

  it "link_to_profile links to current user" do
    user = User.create!(first_name: 'U', email: 'u@e.co', password: 'AAbbcc1122!!', verified_at: Time.now)
    helper.singleton_class.send(:define_method, :current_user) { user }
    expect(helper.link_to_profile).to include(admin_user_path(user))
  end

  it "page_cached_at formats for within 4 hours, older today, and previous day" do
    Timecop.freeze(Time.current.change(hour: 12)) do
      page = double("page", updated_at: 1.hour.ago)
      expect(page_cached_at(page)).to include('ago')

      page = double("page", updated_at: 6.hours.ago)
      expect(page_cached_at(page)).to match(/Today, /)

      page = double("page", updated_at: 1.day.ago)
      expect(page_cached_at(page)).to match(/\w{3} \d{2}, \d{4}/)
    end
  end

  it "editor_class_for returns css class" do
    expect(editor_class_for(double)).to eq('big wysiwyg')
  end
end