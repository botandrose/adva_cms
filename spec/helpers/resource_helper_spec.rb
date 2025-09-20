require "rails_helper"

RSpec.describe ResourceHelper, type: :helper do
  include ResourceHelper

  ResourceDummy = Struct.new(:id)

  it "normalizes resource type for Section and symbols" do
    expect(normalize_resource_type(:show, nil, Section.new)).to eq('section')
    expect(normalize_resource_type(:index, :article, ResourceDummy.new(1))).to eq('articles')
  end

  it "composes resource url method" do
    expect(resource_url_method(:admin, :edit, 'article', only_path: true)).to eq('edit_admin_article_path')
    expect(resource_url_method(nil, :show, 'site', only_path: false)).to eq('site_url')
  end

  it "builds link id" do
    rec = ResourceDummy.new(42)
    expect(resource_link_id(:edit, 'article', rec)).to eq('edit_article')
    expect(resource_link_id(:index, 'articles', rec)).to eq('index_articles')
  end

  it "builds delete options with default confirm" do
    expect(resource_delete_options('article', {})).to eq({ data: { confirm: 'Are you sure you want to delete this articles?' }, method: :delete })
  end
end
