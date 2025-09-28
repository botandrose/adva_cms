require "rails_helper"

RSpec.describe ActivitiesHelper, type: :helper do
  include ActivitiesHelper

  let(:site) { Site.create!(name: 'n2', title: 't2', host: 'helper2.local') }
  let(:section) { Page.create!(site: site, title: 'p2', permalink: 'p2') }
  let(:user) { User.create!(first_name: 'U', email: 'u2@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

  it "activity_datetime with short true uses time only window" do
    base = Time.zone.parse('2024-01-01 10:00:00')
    a = Activity.create!(site: site, section: section, object: Article.new, author: user, actions: ['created'], created_at: base)
    b = Activity.create!(site: site, section: section, object: Article.new, author: user, actions: ['updated'], created_at: base + 30.minutes)
    b.siblings << a
    expect(activity_datetime(b, true)).to include(':')
  end

  it "activity_datetime spans different days" do
    a = Activity.create!(site: site, section: section, object: Article.new, author: user, actions: ['created'], created_at: Time.zone.parse('2024-01-01 20:00:00'))
    b = Activity.create!(site: site, section: section, object: Article.new, author: user, actions: ['updated'], created_at: Time.zone.parse('2024-01-02 10:00:00'))
    b.siblings << a
    text = activity_datetime(b)
    expect(text).to include('Jan')
    expect(text).to include(' - ')
  end

  it "activity_datetime same day but with range" do
    a = Activity.create!(site: site, section: section, object: Article.new, author: user, actions: ['created'], created_at: Time.zone.parse('2024-01-01 10:00:00'))
    b = Activity.create!(site: site, section: section, object: Article.new, author: user, actions: ['updated'], created_at: Time.zone.parse('2024-01-01 11:00:00'))
    b.siblings << a
    text = activity_datetime(b)
    expect(text).to include(' - ')
  end

  it "link_to_activity_user for anonymous author falls back to author_link" do
    user = User.create!(first_name: 'Anon', email: 'anon@example.com', password: 'AAbbcc1122!!', verified_at: Time.now)
    activity = Activity.create!(site: site, section: section, object: Article.new, author: user, actions: ['created'])
    allow(activity.author).to receive(:registered?).and_return(false)
    expect(link_to_activity_user(activity)).to include('mailto:')
  end
end
