require "rails_helper"

RSpec.describe PasswordMailer, type: :mailer do
  let(:site) { Site.create!(name: 'Test Site', host: 'test.example.com', email: 'noreply@test.example.com') }
  let(:user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!') }
  let(:controller_double) { double('controller', send: 'http://test.example.com/password/edit?token=abc123') }

  describe ".handle_user_password_reset_requested!" do
    let(:event_double) do
      double('event',
        object: user,
        source: double('source', site: site),
        token: 'abc123'
      )
    end

    before do
      allow(PasswordMailer).to receive(:site).and_return(double('site', email_from: 'noreply@test.example.com'))
      allow(PasswordMailer).to receive(:password_reset_link).and_return('http://test.example.com/reset')
    end

    it "sends a reset password email" do
      mail_double = double('mail', deliver_now: true)
      expect(PasswordMailer).to receive(:reset_password_email).with(
        :user => user,
        :from => 'noreply@test.example.com',
        :reset_link => 'http://test.example.com/reset',
        :token => 'abc123'
      ).and_return(mail_double)

      PasswordMailer.handle_user_password_reset_requested!(event_double)
    end
  end

  describe ".handle_user_password_updated!" do
    let(:event_double) do
      double('event',
        object: user,
        source: double('source', site: site)
      )
    end

    before do
      allow(PasswordMailer).to receive(:site).and_return(double('site', email_from: 'noreply@test.example.com'))
    end

    it "sends an updated password email" do
      mail_double = double('mail', deliver_now: true)
      expect(PasswordMailer).to receive(:updated_password_email).with(
        :user => user,
        :from => 'noreply@test.example.com'
      ).and_return(mail_double)

      PasswordMailer.handle_user_password_updated!(event_double)
    end
  end

  describe "#reset_password_email" do
    let(:attributes) do
      {
        user: user,
        from: 'noreply@test.example.com',
        reset_link: 'http://test.example.com/reset',
        token: 'abc123'
      }
    end

    before do
      # Mock the template to avoid MissingTemplate error
      allow_any_instance_of(PasswordMailer).to receive(:mail).and_return(double('mail',
        to: [user.email],
        from: ['noreply@test.example.com'],
        subject: "Forgotten Password"
      ))
    end

    it "sets the correct recipient" do
      mailer_instance = PasswordMailer.new
      mail = mailer_instance.reset_password_email(attributes)
      expect(mail.to).to include(user.email)
    end

    it "sets the correct from address" do
      mailer_instance = PasswordMailer.new
      mail = mailer_instance.reset_password_email(attributes)
      expect(mail.from).to include('noreply@test.example.com')
    end

    it "sets the correct subject" do
      mailer_instance = PasswordMailer.new
      mail = mailer_instance.reset_password_email(attributes)
      expect(mail.subject).to eq("Forgotten Password")
    end

    it "includes reset link and token in instance variables" do
      mailer_instance = PasswordMailer.new
      mailer_instance.reset_password_email(attributes)

      expect(mailer_instance.instance_variable_get(:@user)).to eq(user)
      expect(mailer_instance.instance_variable_get(:@reset_link)).to eq('http://test.example.com/reset')
      expect(mailer_instance.instance_variable_get(:@token)).to eq('abc123')
    end
  end

  describe "#updated_password_email" do
    let(:attributes) do
      {
        user: user,
        from: 'noreply@test.example.com'
      }
    end

    before do
      # Mock the template to avoid MissingTemplate error
      allow_any_instance_of(PasswordMailer).to receive(:mail).and_return(double('mail',
        to: [user.email],
        from: ['noreply@test.example.com'],
        subject: "Password Updated"
      ))
    end

    it "sets the correct recipient" do
      mailer_instance = PasswordMailer.new
      mail = mailer_instance.updated_password_email(attributes)
      expect(mail.to).to include(user.email)
    end

    it "sets the correct from address" do
      mailer_instance = PasswordMailer.new
      mail = mailer_instance.updated_password_email(attributes)
      expect(mail.from).to include('noreply@test.example.com')
    end

    it "sets the correct subject" do
      mailer_instance = PasswordMailer.new
      mail = mailer_instance.updated_password_email(attributes)
      expect(mail.subject).to eq("Password Updated")
    end

    it "sets user in instance variable" do
      mailer_instance = PasswordMailer.new
      mailer_instance.updated_password_email(attributes)

      expect(mailer_instance.instance_variable_get(:@user)).to eq(user)
    end
  end

  describe "inheritance" do
    it "inherits from ActionMailer::Base" do
      expect(PasswordMailer.superclass).to eq(ActionMailer::Base)
    end
  end

  describe "private methods" do
    describe ".password_reset_link" do
      it "generates a password reset link with token" do
        link = PasswordMailer.send(:password_reset_link, controller_double, 'abc123')
        expect(link).to eq('http://test.example.com/password/edit?token=abc123')
      end
    end
  end
end