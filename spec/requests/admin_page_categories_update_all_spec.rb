require "rails_helper"

RSpec.describe "Admin::Page::Categories", type: :request do
  let!(:site) { Site.find_by_host("site-with-pages.com") || Site.create!(name: "site with pages", title: "site with pages title", host: "site-with-pages.com") }
  let!(:section) { site.sections.first || Page.create!(site: site, title: "a page", permalink: "a-page", comment_age: 0) }

  before do
    host! site.host
    login_as_admin
  end

  describe "update_all" do
    # The tree widget posts parent_id and left_id per row. left_id is not a
    # column, so these must not be mass-assigned.
    it "nests a category under the given parent and rebuilds paths" do
      parent = section.categories.create!(title: "Parent")
      child = section.categories.create!(title: "Child")

      put admin_page_categories_path(section), params: {
        categories: {
          parent.id.to_s => { parent_id: "", left_id: "" },
          child.id.to_s => { parent_id: parent.id.to_s, left_id: "" },
        },
      }

      expect(response).to have_http_status(:ok)
      expect(child.reload.parent_id).to eq(parent.id)
      expect(child.path).to eq("#{parent.permalink}/#{child.permalink}")
    end

    it "reorders roots according to left_id" do
      a = section.categories.create!(title: "A")
      b = section.categories.create!(title: "B")
      c = section.categories.create!(title: "C")
      expect(section.categories.roots.pluck(:title)).to eq(%w[A B C])

      put admin_page_categories_path(section), params: {
        categories: { c.id.to_s => { parent_id: "", left_id: a.id.to_s } },
      }

      expect(response).to have_http_status(:ok)
      expect(section.categories.reload.roots.pluck(:title)).to eq(%w[A C B])
    end

    it "promotes a nested category back to a root" do
      parent = section.categories.create!(title: "Parent")
      child = section.categories.create!(title: "Child", parent_id: parent.id)
      expect(child.reload.parent_id).to eq(parent.id)

      put admin_page_categories_path(section), params: {
        categories: { child.id.to_s => { parent_id: "", left_id: "" } },
      }

      expect(response).to have_http_status(:ok)
      expect(child.reload.parent_id).to be_nil
    end

    # The lookup is scoped to @section, so a foreign id raises RecordNotFound.
    # Host apps map that to a 404; the bare internal app here renders a 500.
    it "refuses to move a category belonging to another section" do
      other_section = Page.create!(site: site, title: "other page", permalink: "other-page", comment_age: 0)
      mine = section.categories.create!(title: "Mine")
      theirs = other_section.categories.create!(title: "Theirs")

      put admin_page_categories_path(section), params: {
        categories: { theirs.id.to_s => { parent_id: mine.id.to_s, left_id: "" } },
      }

      expect(response).not_to have_http_status(:ok)
      expect(theirs.reload.parent_id).to be_nil
      expect(theirs.section_id).to eq(other_section.id)
    end
  end

  it "create/update failure paths still render form" do
    allow_any_instance_of(Category).to receive(:save).and_return(false)
    post admin_page_categories_path(section), params: { category: { title: "X" } }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<form")

    cat = section.categories.create!(title: "Y")
    allow_any_instance_of(Category).to receive(:update).and_return(false)
    put admin_page_category_path(section, cat), params: { category: { title: "Z" } }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<form")
  end

  it "destroy failure renders edit page" do
    cat = section.categories.create!(title: "D")
    allow_any_instance_of(Category).to receive(:destroy).and_return(false)
    delete admin_page_category_path(section, cat)
    expect(response).to have_http_status(:ok)
  end
end
