require "rails_helper"

RSpec.describe Tag, type: :model do
  describe "creation" do
    it "can be created" do
      tag = Tag.create(name: "test")
      expect(tag).to be_valid
    end

    it "can be found" do
      Tag.create(name: "test")
      tag = Tag.find_by_name("test")
      expect(tag).to_not be_nil
    end
  end
end
