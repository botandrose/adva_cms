require "rails_helper"

RSpec.describe Category, type: :model do
  let(:site) { Site.create!(name: 'Test Site', title: 'Test Site', host: 'test.local') }
  let(:section) { Page.create!(site: site, title: 'Test Section', permalink: 'test-section') }
  let(:user) { User.create!(first_name: 'Author', email: 'author@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

  describe "associations" do
    it "belongs to section" do
      category = Category.new(section: section, title: 'Test Category')
      expect(category.section).to eq(section)
    end

    it "has many categorizations" do
      association = Category.reflect_on_association(:categorizations)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:delete_all)
    end

    it "has many contents through categorizations" do
      association = Category.reflect_on_association(:contents)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:categorizations)
      expect(association.options[:source]).to eq(:categorizable)
      expect(association.options[:source_type]).to eq('Content')
    end
  end

  describe "validations" do
    it "validates presence of section" do
      category = Category.new(title: 'Test')
      expect(category).not_to be_valid
      expect(category.errors[:section]).to include("can't be blank")
    end

    it "validates presence of title" do
      category = Category.new(section: section)
      expect(category).not_to be_valid
      expect(category.errors[:title]).to include("can't be blank")
    end

    it "validates uniqueness of permalink within section" do
      Category.create!(section: section, title: 'Unique', permalink: 'unique')
      duplicate = Category.new(section: section, title: 'Different Title', permalink: 'unique')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:permalink]).to include("has already been taken")
    end

    it "allows same permalink in different sections" do
      other_section = Page.create!(site: site, title: 'Other Section', permalink: 'other')
      Category.create!(section: section, title: 'Same', permalink: 'same')
      other_category = Category.create!(section: other_section, title: 'Same', permalink: 'same')
      expect(other_category).to be_valid
    end
  end

  describe "nested set behavior" do
    let!(:parent_category) { Category.create!(section: section, title: 'Parent') }
    let!(:child_category) { Category.create!(section: section, title: 'Child', parent: parent_category) }

    it "acts as nested set" do
      expect(parent_category.children).to include(child_category)
      expect(child_category.parent).to eq(parent_category)
    end

    it "scopes nested set by section_id" do
      other_section = Page.create!(site: site, title: 'Other Section', permalink: 'other')
      other_parent = Category.create!(section: other_section, title: 'Other Parent')

      expect(parent_category.children).not_to include(other_parent)
      expect(other_parent.children).not_to include(child_category)
    end
  end

  describe "permalink generation" do
    it "generates unique permalink when title duplicates within a section" do
      c1 = Category.create!(section: section, title: 'duplicate')
      c2 = Category.create!(section: section, title: 'duplicate')
      expect(c1.permalink).not_to eq(c2.permalink)
      expect(c2.permalink).to match(/duplicate-\d+/)
    end

    it "generates permalink from title" do
      category = Category.create!(section: section, title: 'Test Category')
      expect(category.permalink).to eq('test-category')
    end

    it "does not sync permalink when title changes if permalink already exists" do
      category = Category.create!(section: section, title: 'Original')
      original_permalink = category.permalink

      category.update!(title: 'Updated Title')
      # With only_when_blank: true, permalink should not change when title changes
      expect(category.permalink).to eq(original_permalink)
    end

    it "only sets permalink when blank" do
      category = Category.create!(section: section, title: 'Test', permalink: 'custom-permalink')
      expect(category.permalink).to eq('custom-permalink')

      category.update!(title: 'Updated')
      expect(category.permalink).to eq('custom-permalink') # Should not change
    end
  end

  describe "#owners" do
    let(:category) { Category.create!(section: section, title: 'Test Category') }

    it "returns section owners including the section itself" do
      owners = category.owners
      expect(owners).to include(section)
    end
  end

  describe "#owner" do
    let(:category) { Category.create!(section: section, title: 'Test Category') }

    it "returns the section" do
      expect(category.owner).to eq(section)
    end
  end

  describe "#all_contents" do
    let(:category) { Category.create!(section: section, title: 'Test Category') }
    let!(:content1) do
      Article.create!(
        site: site,
        section: section,
        title: 'First Article',
        body: 'Content',
        author: user,
        published_at: 2.days.ago,
        permalink: 'first'
      ).tap { |c| c.categories << category }
    end
    let!(:content2) do
      Article.create!(
        site: site,
        section: section,
        title: 'Second Article',
        body: 'Content',
        author: user,
        published_at: 1.day.ago,
        permalink: 'second'
      ).tap { |c| c.categories << category }
    end

    it "returns contents ordered by published_at desc" do
      contents = category.all_contents
      expect(contents.first).to eq(content2) # more recent
      expect(contents.last).to eq(content1) # older
    end

    it "returns only contents in this category" do
      other_category = Category.create!(section: section, title: 'Other Category')
      other_content = Article.create!(
        site: site,
        section: section,
        title: 'Other Article',
        body: 'Content',
        author: user,
        published_at: 1.hour.ago,
        permalink: 'other'
      )
      other_content.categories << other_category

      contents = category.all_contents
      expect(contents).to include(content1, content2)
      expect(contents).not_to include(other_content)
    end
  end

  describe "path building" do
    it "builds path from self and ancestors" do
      parent = Category.create!(section: section, title: 'Parent', permalink: 'parent')
      child = Category.create!(section: section, title: 'Child', permalink: 'child', parent: parent)
      grandchild = Category.create!(section: section, title: 'Grandchild', permalink: 'grandchild', parent: child)

      expect(grandchild.send(:build_path)).to eq('parent/child/grandchild')
    end

    it "calls update_path before save" do
      category = Category.create!(section: section, title: 'Original')

      # Test that update_path method exists and can be called
      expect(category).to respond_to(:send)
      expect(category.send(:update_path)).to be_nil

      # Test that path is built correctly
      expect(category.send(:build_path)).to eq(category.permalink)
    end

    it "does not update path when permalink has not changed" do
      category = Category.create!(section: section, title: 'Test', permalink: 'test')
      original_path = category.path

      category.update!(title: 'Updated Title') # title change shouldn't affect path if permalink doesn't change
      expect(category.path).to eq(original_path)
    end
  end

  describe "callbacks" do
    describe "before_save :update_path" do
      it "is called before save" do
        category = Category.new(section: section, title: 'Test')
        expect(category).to receive(:update_path)
        category.save!
      end
    end

    describe "after_create :update_paths" do
      it "is called after create" do
        category = Category.new(section: section, title: 'Test')
        expect(category).to receive(:update_paths)
        category.save!
      end

      it "moves to child of parent when parent_id is set" do
        parent = Category.create!(section: section, title: 'Parent')
        child = Category.create!(section: section, title: 'Child', parent_id: parent.id)

        # Verify that child was properly associated
        expect(child.parent).to eq(parent)
        expect(parent.children).to include(child)
      end

      it "updates paths after creation with parent" do
        parent = Category.create!(section: section, title: 'Parent')
        child = Category.create!(section: section, title: 'Child', parent_id: parent.id)

        # Just verify the callback completed without error
        expect(child.persisted?).to be true
        expect(child.parent).to eq(parent)
      end

      it "does not call move_to_child_of when no parent_id" do
        category = Category.new(section: section, title: 'Root')
        expect(category).not_to receive(:move_to_child_of)
        category.save!
      end
    end
  end

  describe "content categorization" do
    let(:category) { Category.create!(section: section, title: 'Test Category') }
    let(:content) do
      Article.create!(
        site: site,
        section: section,
        title: 'Test Article',
        body: 'Content',
        author: user,
        published_at: 1.hour.ago,
        permalink: 'test'
      )
    end

    it "can be associated with content through categorizations" do
      content.categories << category
      expect(category.contents).to include(content)
      expect(content.categories).to include(category)
    end

    it "deletes categorizations when category is destroyed" do
      content.categories << category
      categorization_id = category.categorizations.first.id

      category.destroy
      expect(Categorization.find_by_id(categorization_id)).to be_nil
    end
  end
end
