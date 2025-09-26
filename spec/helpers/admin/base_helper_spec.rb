require "rails_helper"

RSpec.describe Admin::BaseHelper, type: :helper do
  include Admin::BaseHelper

  it "formats page_cached_at within 4 hours as ago or Today" do
    # Use a time that's definitely today in the current timezone
    updated_at = Time.current - 60.seconds
    page = Struct.new(:updated_at).new(updated_at)
    txt = page_cached_at(page)
    expect(txt).to match(/ago|Today/)
  end
end

