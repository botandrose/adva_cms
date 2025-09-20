require "rails_helper"

RSpec.describe User, type: :model do
  it "validates presence of first_name and email" do
    u = User.new
    expect(u).not_to be_valid
    u.first_name = 'a'
    u.email = 'a@example.com'
    u.password = 'AAbbcc1122!!'
    expect(u).to be_valid
  end

  it "enforces password complexity when required" do
    u = User.new(first_name: 'a', email: 'a2@example.com', password: 'simple')
    expect(u).not_to be_valid
  end
end

