require "rails_helper"

RSpec.describe Adva::ExtensibleFormBuilder do
  let(:template) { double("Template", assigns: {}, controller: double("Ctrl", instance_variable_names: [], instance_variable_get: nil)) }
  let(:object)   { Object.new }
  subject(:builder) { described_class.new(:obj, object, template, {}) }

  # pick_form_builder lives on FormHelper; exercising other builder internals instead

  it "add_default_class_names merges defaults into options" do
    described_class.default_class_names(:field_set) << "alpha"
    opts = builder.send(:add_default_class_names, { class: "beta" }, :field_set)
    expect(opts[:class]).to include("alpha")
    expect(opts[:class]).to include("beta")
  end

  it "with_callbacks wraps strings before/after around block output" do
    described_class.before(:obj, :thing, "BEFORE")
    described_class.after(:obj, :thing, "AFTER")
    out = builder.send(:with_callbacks, :thing) { "BODY" }
    expect(out).to include("BEFORE")
    expect(out).to include("BODY")
    expect(out).to include("AFTER")
  end

  it "add_tabindex computes positions from symbols and hashes" do
    # baseline increments
    a = builder.send(:add_tabindex, {}, :input)
    expect(a[:tabindex]).to be_a(Integer)

    # same as an existing index
    first = a[:tabindex]
    # simulate remember by setting internal store
    builder.send(:tabindexes)[:"field_id"] = first
    same = builder.send(:add_tabindex, { tabindex: :field_id }, :input)
    expect(same[:tabindex]).to eq(first)

    # before/after on hash
    builder.send(:tabindexes)[:"x"] = 10
    before = builder.send(:add_tabindex, { tabindex: { before: :x } }, :input)
    after  = builder.send(:add_tabindex, { tabindex: { after: :x } }, :input)
    expect(before[:tabindex]).to eq(9)
    expect(after[:tabindex]).to eq(11)
  end

  describe "default_class_names" do
    it "returns the hash when no type is given" do
      result = described_class.default_class_names
      expect(result).to be_a(Hash)
    end
  end

  describe "render" do
    it "delegates to template render" do
      expect(template).to receive(:send).with(:render, :partial, { name: "test" })
      builder.send(:render, :partial, { name: "test" })
    end
  end

  describe "wrap" do
    it "wraps content in a paragraph tag" do
      allow(template).to receive(:content_tag).with(:p, "content").and_return("<p>content</p>")
      result = builder.send(:wrap, "content")
      expect(result).to eq("<p>content</p>")
    end
  end

  describe "hint" do
    it "appends a hint span to the tag" do
      allow(template).to receive(:content_tag).with(:span, "", title: "hint text", class: 'hint', for: "field_id").and_return('<span title="hint text" class="hint" for="field_id"></span>')
      tag = '<input id="field_id" type="text"/>'
      result = builder.send(:hint, tag, "hint text")
      expect(result).to include("field_id")
    end
  end

  describe "remember_tabindex" do
    it "stores tabindex by id extracted from tag" do
      tag = '<input id="my_field" type="text"/>'
      builder.send(:remember_tabindex, tag, { tabindex: 5 })
      expect(builder.send(:tabindexes)[:my_field]).to eq(5)
    end
  end

  describe "run_callbacks with proc" do
    it "evaluates proc callbacks with instance_eval" do
      described_class.before(:obj, :test, proc { "PROC_OUTPUT" })
      result = builder.send(:run_callbacks, :before, :test)
      expect(result).to include("PROC_OUTPUT")
    end
  end

  describe "extract_id" do
    it "extracts the id attribute from an HTML tag" do
      tag = '<input id="my_id" name="test"/>'
      result = builder.send(:extract_id, tag)
      expect(result).to eq("my_id")
    end
  end
end

RSpec.describe ActionView::Helpers::FormHelper do
  let(:view_context) do
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    view.output_buffer = ActiveSupport::SafeBuffer.new
    view
  end

  describe "singular_class_name" do
    it "returns the singular form of a class name" do
      test_class = Class.new do
        def self.model_name
          ActiveModel::Name.new(self, nil, "TestUsers")
        end
      end
      result = view_context.send(:singular_class_name, test_class)
      expect(result).to eq("test_users")
    end
  end

  describe "pick_form_builder" do
    it "returns the default form builder when constantize fails" do
      result = view_context.send(:pick_form_builder, :nonexistent_builder)
      expect(result.ancestors).to include(ActionView::Helpers::FormBuilder)
    end

    it "rescues when const_set fails and returns default form builder" do
      allow(Object).to receive(:const_set).and_raise(NameError)
      result = view_context.send(:pick_form_builder, :another_nonexistent)
      expect(result).to eq(ActionView::Base.default_form_builder)
    end
  end
end
