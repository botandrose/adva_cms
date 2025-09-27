require "rails_helper"

RSpec.describe "AuthenticateUser validate_token" do
  it "validate_token parses id;token and authenticates" do
    controller = BaseController.new

    dummy = Class.new do
      def self.find_by_id(uid)
        Struct.new(:expected).new('abc').tap do |obj|
          def obj.authenticate(tok); tok == expected; end
        end
      end
    end

    expect(controller.send(:validate_token, dummy, '1;abc')).not_to be_nil
    expect(controller.send(:validate_token, dummy, '1;nope')).to be_nil
  end

  it "validate_token returns nil for blank or malformed tokens" do
    controller = BaseController.new
    expect(controller.send(:validate_token, Object, nil)).to be_nil
    expect(controller.send(:validate_token, Object, 'nodelimiter')).to be_nil
  end
end
