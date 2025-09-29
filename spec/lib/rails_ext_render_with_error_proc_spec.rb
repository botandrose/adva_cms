require "rails_helper"

RSpec.describe "RenderWithErrorProc", type: :request do
  it "extracts error proc key from options and restores field_error_proc" do
    controller = BaseController.new

    original = ActionView::Base.field_error_proc
    current_inside = nil

    result = controller.send(:with_error_proc, :above_field) do
      current_inside = ActionView::Base.field_error_proc
      :ok
    end

    expect(result).to eq(:ok)
    expect(current_inside).to eq(ActionController::Base.field_error_procs[:above_field])
    expect(ActionView::Base.field_error_proc).to eq(original)
  end

  it "raises on invalid error proc key" do
    controller = BaseController.new
    expect { controller.send(:with_error_proc, :nope) { :ok } }.to raise_error(/invalid error_proc_key/)
  end

  it "extracts explicit :errors key or defaults to class default" do
    klass = Class.new(BaseController) do
      renders_with_error_proc :below_field
    end

    ctrl = klass.new
    expect(ctrl.send(:extract_error_proc_key, {})).to eq(:below_field)
    expect(ctrl.send(:extract_error_proc_key, errors: :above_field)).to eq(:above_field)
  end

  describe "field_error_procs" do
    let(:instance) { double("instance", error_message: ["can't be blank"])}

    describe ":above_field" do
      let(:proc) { ActionController::Base.field_error_procs[:above_field] }

      it "should render the error message before the field" do
        html_tag = '<input type="text" />'.html_safe
        expected = '<span class="error_message">can\'t be blank</span><input type="text" />'
        expect(proc.call(html_tag, instance)).to eq(expected)
      end

      it "should not render the error message for a label" do
        html_tag = '<label for="field">Field</label>'
        expect(proc.call(html_tag, instance)).to eq(html_tag)
      end
    end

    describe ":below_field" do
      let(:proc) { ActionController::Base.field_error_procs[:below_field] }

      it "should render the error message after the field" do
        html_tag = '<input type="text" />'.html_safe
        expected = '<input type="text" /><span class="error_message">can\'t be blank</span>'
        expect(proc.call(html_tag, instance)).to eq(expected)
      end

      it "should not render the error message for a label" do
        html_tag = '<label for="field">Field</label>'
        expect(proc.call(html_tag, instance)).to eq(html_tag)
      end
    end
  end
end