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

  it "formats email_with_name and builds homepage with scheme" do
    u = User.new(first_name: 'Jane', last_name: 'Doe', email: 'jane@example.com', password: 'AAbbcc1122!!')
    expect(u.email_with_name).to eq('Jane Doe <jane@example.com>')

    u.homepage = 'example.com'
    expect(u.homepage).to eq('http://example.com')
    u.homepage = 'http://example.com'
    expect(u.homepage).to eq('http://example.com')
  end

  it "derives name and first_name_from_email when first_name blank" do
    u = User.new(email: 'nickname@example.com', password: 'AAbbcc1122!!')
    expect(u.first_name_from_email).to eq('nickname')
    u.first_name = 'Given'
    expect(u.first_name_from_email).to eq('Given')
    u.last_name = 'Surname'
    expect(u.name).to eq('Given Surname')
    u.last_name = nil
    expect(u.name).to eq('Given')
  end
end
