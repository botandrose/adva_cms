require "rails_helper"

RSpec.describe ActionController::EventHelper do
  it "builds event type and triggers Adva::Event" do
    controller = BaseController.new
    obj = double("Content")
    allow(obj).to receive_message_chain(:class, :name).and_return("Content")
    allow_any_instance_of(ActionController::Base).to receive(:trigger_event).and_call_original

    expect(Adva::Event).to receive(:trigger).with(:content_published, obj, controller, { foo: 1 })
    controller.send(:trigger_event, obj, :published, foo: 1)
  end

  it "triggers multiple changes via trigger_events" do
    controller = BaseController.new
    obj = double("Content")
    allow(obj).to receive_message_chain(:class, :name).and_return("Content")
    allow_any_instance_of(ActionController::Base).to receive(:trigger_events).and_call_original
    allow_any_instance_of(ActionController::Base).to receive(:trigger_event).and_call_original

    expect(Adva::Event).to receive(:trigger).twice
    controller.send(:trigger_events, obj, :created, :updated)
  end
end
