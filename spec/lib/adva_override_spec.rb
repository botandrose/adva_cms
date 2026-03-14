require "rails_helper"

RSpec.describe Adva::Override do
  after { Adva::Override.reset! }

  let(:site) { Site.create!(name: "test", title: "test", host: "test.local") }
  let(:page) { Page.create!(site: site, title: "page", permalink: "page") }
  let(:user) { User.create!(first_name: "user", email: "user@ex.com", password: "AAbbcc1122!!", verified_at: Time.now) }

  describe ".call" do
    context "with controller parameter" do
      it "overrides a controller method using prepend" do
        # Override a simple method that doesn't need request context
        Adva::Override.call(controller: "articles") do
          def custom_test_method
            "overridden_value"
          end
        end

        controller = ArticlesController.new
        expect(controller.custom_test_method).to eq("overridden_value")
      end

      it "converts controller name to proper path" do
        expect {
          Adva::Override.call(controller: "admin/sites") do
            def custom_method
              "overridden"
            end
          end
        }.not_to raise_error

        expect(Admin::SitesController.new.respond_to?(:custom_method)).to eq(true)
      end
    end

    context "with model parameter" do
      it "overrides a model method using prepend" do
        Adva::Override.call(model: "user") do
          def email
            "overridden@example.com"
          end
        end

        user = User.new(email: "original@example.com")
        expect(user.email).to eq("overridden@example.com")
      end

      it "allows calling super to access original method" do
        Adva::Override.call(model: "site") do
          def name
            "Site: #{super}"
          end
        end

        site = Site.new(name: "Test")
        expect(site.name).to eq("Site: Test")
      end
    end

    context "without parameters" do
      it "raises ArgumentError" do
        expect {
          Adva::Override.call do
            def some_method; end
          end
        }.to raise_error(ArgumentError, "Must specify either controller: or model:")
      end
    end

    context "with both parameters" do
      it "prioritizes controller over model" do
        expect {
          Adva::Override.call(controller: "articles", model: "user") do
            def test_method; end
          end
        }.not_to raise_error

        expect(ArticlesController.new.respond_to?(:test_method)).to eq(true)
      end
    end
  end

  describe "Adva.override convenience method" do
    it "delegates to Adva::Override.call" do
      Adva.override(model: "category") do
        def title_with_prefix
          "Category: #{title}"
        end
      end

      category = Category.new(title: "Test")
      expect(category.title_with_prefix).to eq("Category: Test")
    end
  end

  describe "#path_to_class_name (private)" do
    it "converts controller paths to class names" do
      # Test indirectly by verifying correct class is modified
      Adva::Override.call(controller: "admin/page/articles") do
        def test_path_conversion
          "converted"
        end
      end

      expect(Admin::Page::ArticlesController.new.test_path_conversion).to eq("converted")
    end

    it "converts model paths to class names" do
      # Test indirectly by verifying correct class is modified
      Adva::Override.call(model: "article") do
        def test_model_conversion
          "converted"
        end
      end

      article = Article.new
      expect(article.test_model_conversion).to eq("converted")
    end
  end

  describe "class_methods" do
    it "adds class methods via singleton_class.prepend" do
      Adva.override(model: "site") do
        class_methods do
          def custom_class_method
            "from override"
          end
        end
      end

      expect(Site.custom_class_method).to eq("from override")
    end

    it "allows calling super to access original class method" do
      Adva.override(model: "site") do
        class_methods do
          def find_or_initialize_by(*)
            result = super
            result.name ||= "default"
            result
          end
        end
      end

      site = Site.find_or_initialize_by(host: "nonexistent.local")
      expect(site.name).to eq("default")
    end
  end

  describe "included" do
    it "evaluates block in class context" do
      Adva.override(model: "site") do
        included do
          has_many :categories, through: :sections
        end
      end

      expect(Site.reflect_on_association(:categories)).to be_present
    end
  end

  describe "prepend behavior" do
    it "maintains method chain order" do
      # Use a class variable to track calls across the module boundary
      Article.class_variable_set(:@@override_calls, [])

      Adva::Override.call(model: "article") do
        def title
          self.class.class_variable_get(:@@override_calls) << "first override"
          super
        end
      end

      Adva::Override.call(model: "article") do
        def title
          self.class.class_variable_get(:@@override_calls) << "second override"
          super
        end
      end

      article = Article.new(
        site: site,
        section: page,
        title: "test",
        body: "test",
        author: user,
        published_at: Time.now
      )
      article.title

      # Second override should be called first due to prepend order
      results = Article.class_variable_get(:@@override_calls)
      expect(results).to eq(["second override", "first override"])
    end
  end
end
