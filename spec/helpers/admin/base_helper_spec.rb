require "rails_helper"

RSpec.describe Admin::BaseHelper, type: :helper do
  include Admin::BaseHelper

  it "formats page_cached_at within 4 hours as ago or Today" do
    page = Struct.new(:updated_at).new(Time.zone.now - 60)
    txt = page_cached_at(page)
    expect(txt).to match(/ago|Today/)
  end
end

