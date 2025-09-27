# frozen_string_literal: true

require "cacheable_flash/version"

RSpec.describe CacheableFlash do
  it "has a version number" do
    expect(CacheableFlash::VERSION).to be_a(String)
    expect(CacheableFlash::VERSION).not_to be_empty
  end
end
