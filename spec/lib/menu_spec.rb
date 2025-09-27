require "rails_helper"

RSpec.describe Menu do
  it "Menu::Base API returns no-op values" do
    m = Menu::Base.new
    expect { m.build }.not_to raise_error
    expect { m.find(:anything) }.not_to raise_error
    expect(m.object).to eq(m)
    expect(m.parent).to eq(m)
    expect(m.root).to eq(m)
    expect(m.active).to be_nil
    expect(m.render).to eq("")
  end
end

