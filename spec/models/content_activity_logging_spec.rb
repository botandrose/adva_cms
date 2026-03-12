require "rails_helper"

RSpec.describe Content, "activity logging" do
  let(:site) { Site.create!(name: "test", title: "test", host: "test.local") }
  let(:section) { Page.create!(site: site, title: "page", permalink: "page") }
  let(:user) { User.create!(first_name: "User", email: "user@example.com", password: "AAbbcc1122!!", verified_at: Time.now) }

  it "logs a 'created' activity when a new article is created" do
    article = Article.create!(site: site, section: section, title: "New Post", body: "body", author: user, published_at: Time.current)
    activity = Activity.last
    expect(activity.actions).to include("created")
    expect(activity.object).to eq(article)
    expect(activity.site).to eq(site)
    expect(activity.section).to eq(section)
    expect(activity.author).to eq(user)
    expect(activity.object_attributes).to include("title" => "New Post", "type" => "Article")
  end

  it "logs a 'revised' activity when an existing article is updated" do
    article = Article.create!(site: site, section: section, title: "Post", body: "body", author: user, published_at: Time.current)
    Activity.delete_all

    article.update!(title: "Updated Post")
    activity = Activity.last
    expect(activity.actions).to include("revised")
    expect(activity.object).to eq(article)
  end

  it "logs a 'published' activity when an article is published" do
    article = Article.create!(site: site, section: section, title: "Draft", body: "body", author: user)
    Activity.delete_all

    article.update!(published_at: Time.current)
    activity = Activity.last
    expect(activity.actions).to include("published")
  end

  it "logs an 'unpublished' activity when an article is unpublished" do
    article = Article.create!(site: site, section: section, title: "Post", body: "body", author: user, published_at: Time.current)
    Activity.delete_all

    article.update!(published_at: nil)
    activity = Activity.last
    expect(activity.actions).to include("unpublished")
  end

  it "does not create an activity when nothing meaningful changed" do
    article = Article.create!(site: site, section: section, title: "Post", body: "body", author: user, published_at: Time.current)
    Activity.delete_all

    article.save!
    expect(Activity.count).to eq(0)
  end

  it "logs a 'deleted' activity when an article is destroyed" do
    article = Article.create!(site: site, section: section, title: "Doomed", body: "body", author: user, published_at: Time.current)
    Activity.delete_all

    article.destroy!
    activity = Activity.last
    expect(activity.actions).to include("deleted")
    expect(activity.object_attributes).to include("title" => "Doomed")
  end
end
