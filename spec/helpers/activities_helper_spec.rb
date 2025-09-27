require "rails_helper"

RSpec.describe ActivitiesHelper, type: :helper do
  include ActivitiesHelper

  let(:site) { Site.create!(name: 'n', title: 't', host: 'helper.local') }
  let(:section) { Page.create!(site: site, title: 'p', permalink: 'p') }
  let(:user) { User.create!(first_name: 'U', email: 'u@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

  describe "#render_activities" do
    it "renders a list of activities" do
      article = Article.create!(site: site, section: section, title: 'A', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'a')
      activity = Activity.create!(site: site, section: section, object: article, author: user, actions: ['created'])
      allow(self).to receive(:render).with(partial: "admin/activities/content", locals: { activity: activity, recent: false }).and_return("<li>activity</li>")
      expect(render_activities([activity])).to eq("<ul class=\"activities\"><li>activity</li></ul>")
    end

    it "renders a message when there are no activities" do
      expect(render_activities([])).to eq("<ul class=\"activities\"><li class=\"empty shade\">Nothing happened.</li></ul>")
    end
  end

  describe "#activity_css_classes" do
    it "returns the correct css classes" do
      article = Article.create!(site: site, section: section, title: 'A', body: 'b', author: user, published_at: 1.hour.ago, permalink: 'a')
      activity = Activity.create!(site: site, section: section, object: article, author: user, actions: ['created'], object_attributes: { 'type' => 'Article' })
      expect(activity_css_classes(activity)).to eq("article_created")
    end
  end

  describe "#activity_datetime" do
    it "returns the correct datetime" do
      activity = Activity.create!(site: site, section: section, object: Article.new, author: user, actions: ['created'])
      expect(activity_datetime(activity)).to eq(activity.created_at.to_fs(:long_ordinal))
    end
  end

  describe "#link_to_activity_user" do
    it "returns a link to the user" do
      activity = Activity.create!(site: site, section: section, object: Article.new, author: user, actions: ['created'])
      expect(link_to_activity_user(activity)).to eq(link_to(user.name, admin_user_path(user)))
    end
  end
end
