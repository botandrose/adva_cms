require "rails_helper"

RSpec.describe Adva::Event do
  before do
    described_class.observers = []
    TestObserverHandleGeneric.instance_variable_set(:@received, []) if defined?(TestObserverHandleGeneric)
    TestObserverHandleSpecific.instance_variable_set(:@received, []) if defined?(TestObserverHandleSpecific)
  end

  class TestObserverHandleSpecific
    def self.handle_article_published!(event); (@received ||= []) << event; end
    def self.received; @received || []; end
  end

  class TestObserverHandleGeneric
    def self.handle_event!(event); (@received ||= []) << event; end
    def self.received; @received || []; end
  end

  it "dispatches to observer specific handler when available" do
    described_class.observers = [TestObserverHandleSpecific]
    obj = double("Article", class: class_double("Article", name: "Article"))

    Adva::Event.trigger(:article_published, obj, :spec, foo: :bar)

    expect(TestObserverHandleSpecific.received.size).to eq(1)
    event = TestObserverHandleSpecific.received.first
    expect(event.type).to eq(:article_published)
    expect(event.object).to eq(obj)
    expect(event.source).to eq(:spec)
    expect(event.options[:foo]).to eq(:bar)
    # method_missing exposes option keys as methods
    expect(event.foo).to eq(:bar)
  end

  it "falls back to generic handler when specific one missing" do
    described_class.observers = [TestObserverHandleGeneric]
    obj = double("Article", class: class_double("Article", name: "Article"))

    Adva::Event.trigger(:article_updated, obj, :spec, a: 1)

    expect(TestObserverHandleGeneric.received.size).to eq(1)
    expect(TestObserverHandleGeneric.received.first.a).to eq(1)
  end

  it "supports string class names in observers list" do
    TestObserverHandleGeneric.instance_variable_set(:@received, [])
    stub_const("StringNamedObserver", TestObserverHandleGeneric)
    described_class.observers = ["StringNamedObserver"]
    obj = double("Article", class: class_double("Article", name: "Article"))

    expect { Adva::Event.trigger(:article_deleted, obj, :spec) }.not_to raise_error
    expect(StringNamedObserver.received.size).to eq(1)
  end

  it "raises NoMethodError for unknown option via method_missing" do
    event = Adva::Event.new(:x, :obj, :src, known: 1)
    expect(event.known).to eq(1)
    expect { event.unknown }.to raise_error(NoMethodError)
  end
end
