require "rails_helper"

RSpec.describe Adva::HasOptions do
  let(:site) { Site.create!(name: 'n', title: 't', host: 'opt.local') }

  before do
    stub_const('DummySection', Class.new(Section))
    DummySection.table_name = 'sections'
    DummySection.has_option :feature_enabled, type: :boolean, default: false
  end

  it "casts boolean options and persists them" do
    s = DummySection.create!(site: site, title: 'd1', permalink: 'd1')
    expect(s.feature_enabled).to eq(false)

    s.feature_enabled = '1'
    expect(s.feature_enabled).to eq(true)
    s.save!

    expect(s.reload.feature_enabled).to eq(true)
    # Ensure serialization stored it in options
    expect(s.options).to include(feature_enabled: true)
  end

  it "reads default when key missing and options initialized" do
    s = DummySection.create!(site: site, title: 'd2', permalink: 'd2')
    s.options = {}
    expect(s.feature_enabled).to eq(false)
  end
end

