require "rails_helper"
require "adva/authenticate_user"

RSpec.describe Adva::AuthenticateUser do
  let!(:site) { Site.find_by_host('test.example.com') || Site.create!(name: 'Test Site', title: 'Test Site', host: 'test.example.com') }
  let!(:user) { User.create!(first_name: 'Test', email: 'test@example.com', password: 'AAbbcc1122!!', verified_at: Time.now) }

  describe ".included" do
    it "extends target with ClassMethods" do
      dummy_class = Class.new do
        def self.helper_method(*methods); end
      end
      dummy_class.include(Adva::AuthenticateUser)

      expect(dummy_class).to respond_to(:authentication_required)
      expect(dummy_class).to respond_to(:no_authentication_required)
    end

    it "sets up helper methods" do
      dummy_class = Class.new do
        def self.helper_method(*methods); end
      end

      expect(dummy_class).to receive(:helper_method).with(:current_user, :logged_in?, :authenticated?)
      dummy_class.include(Adva::AuthenticateUser)
    end
  end

  describe "ClassMethods" do
    let(:dummy_class) do
      Class.new do
        def self.helper_method(*methods); end
        def self.before_action(method); end
        def self.skip_before_action(method); end
        include Adva::AuthenticateUser
      end
    end

    describe ".authentication_required" do
      it "sets up before_action for require_authentication" do
        expect(dummy_class).to receive(:before_action).with(:require_authentication)
        dummy_class.authentication_required
      end
    end

    describe ".no_authentication_required" do
      it "skips before_action for require_authentication" do
        expect(dummy_class).to receive(:skip_before_action).with(:require_authentication)
        dummy_class.no_authentication_required
      end
    end
  end

  describe "#validate_token" do
    let(:dummy_class) do
      Class.new do
        def self.find_by_id(id)
          if id == '123'
            user = Struct.new(:id).new(123)
            def user.authenticate(token)
              token == 'valid_token'
            end
            user
          end
        end
      end
    end

    let(:dummy_controller) do
      Class.new do
        def self.helper_method(*methods); end
        include Adva::AuthenticateUser
      end.new
    end

    it "returns nil for blank token" do
      expect(dummy_controller.send(:validate_token, dummy_class, nil)).to be_nil
      expect(dummy_controller.send(:validate_token, dummy_class, '')).to be_nil
      expect(dummy_controller.send(:validate_token, dummy_class, '   ')).to be_nil
    end

    it "returns nil for token without semicolon" do
      expect(dummy_controller.send(:validate_token, dummy_class, 'no_semicolon')).to be_nil
    end

    it "returns user object when token is valid" do
      result = dummy_controller.send(:validate_token, dummy_class, '123;valid_token')
      expect(result).not_to be_nil
      expect(result.id).to eq(123)
    end

    it "returns nil when token is invalid" do
      result = dummy_controller.send(:validate_token, dummy_class, '123;invalid_token')
      expect(result).to be_nil
    end

    it "returns nil when user is not found" do
      result = dummy_controller.send(:validate_token, dummy_class, '999;valid_token')
      expect(result).to be_nil
    end
  end

  describe "#http_auth_login" do
    let(:dummy_controller) do
      Class.new do
        def self.helper_method(*methods); end
        include Adva::AuthenticateUser
      end.new
    end

    it "is not implemented yet" do
      expect(dummy_controller.send(:http_auth_login)).to be_nil
    end
  end
end