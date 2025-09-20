require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class PageArticlesRoutesTest < ActionController::TestCase
  tests ArticlesController
  with_common :a_page, :an_article

  test "round-trips page path via recognize_path/url_for" do
    section = Section.find_by_permalink('a-page') || Section.first
    skip "no section available" unless section
    path = "/#{section.permalink}"
    params = Rails.application.routes.recognize_path(path, method: :get)
    assert_equal path, @controller.url_for(params.merge(only_path: true))
  end

  test "round-trips article path via recognize_path/url_for" do
    section = Section.find_by_permalink('a-page') || Section.first
    skip "no section available" unless section
    article = section.articles.first
    skip "no article for section" unless article
    path = "/#{section.permalink}/#{article.permalink}"
    params = Rails.application.routes.recognize_path(path, method: :get)
    assert_equal path, @controller.url_for(params.merge(only_path: true))
  end

  test "helper page_path generates permalink path" do
    section = Section.find_by_permalink('a-page') || Section.first
    skip "no section available" unless section
    assert_equal "/#{section.permalink}", page_path(section)
  end

  test "helper page_article_path generates article path" do
    section = Section.find_by_permalink('a-page') || Section.first
    skip "no section available" unless section
    article = section.articles.first
    skip "no article for section" unless article
    assert_equal "/#{section.permalink}/#{article.permalink}", page_article_path(section, article)
  end

  test "helpers accept raw string permalinks" do
    section = Section.find_by_permalink('a-page') || Section.first
    skip "no section available" unless section
    article = section.articles.first
    skip "no article for section" unless article
    assert_equal "/#{section.permalink}", page_path(section.permalink)
    assert_equal "/#{section.permalink}/#{article.permalink}", page_article_path(section.permalink, article.permalink)
  end
end
