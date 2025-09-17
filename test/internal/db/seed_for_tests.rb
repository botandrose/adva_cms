require "active_support/core_ext/time"

if Site.count.zero?
  site = Site.create!(name: "site with pages", title: "site with pages title", host: "site-with-pages.com")

  page = Page.create!(site: site, title: "a page", permalink: "a-page", comment_age: 0)
  Page.create!(site: site, title: "another page", permalink: "another-page", comment_age: 0)
  # keep a single site for simple host resolution in tests

  user = User.create!(first_name: "a user", email: "a-user@example.com", password: "AAbbcc1122!!", verified_at: Time.now)
  Article.create!(site: site, section: page, title: "a page article", body: "body", author: user, published_at: Time.parse('2008-01-01 12:00:00'))
end
