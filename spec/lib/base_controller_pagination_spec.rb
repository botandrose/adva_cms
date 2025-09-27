require "rails_helper"

RSpec.describe BaseController do
  it "current_page returns 1 for 0 or non-numeric, passes negatives" do
    controller = BaseController.new

    allow(controller).to receive(:params).and_return({ page: 0 }.with_indifferent_access)
    expect(controller.send(:current_page)).to eq(1)

    controller.remove_instance_variable(:@page) rescue nil
    allow(controller).to receive(:params).and_return({ page: 'abc' }.with_indifferent_access)
    expect(controller.send(:current_page)).to eq(1)

    controller.remove_instance_variable(:@page) rescue nil
    allow(controller).to receive(:params).and_return({ page: -2 }.with_indifferent_access)
    expect(controller.send(:current_page)).to eq(-2)
  end

  it "current_page defaults to 1 when page missing" do
    controller = BaseController.new
    allow(controller).to receive(:params).and_return({}.with_indifferent_access)
    expect(controller.send(:current_page)).to eq(1)
  end
end
