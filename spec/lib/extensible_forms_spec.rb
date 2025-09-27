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
end
