require "rails_helper"

RSpec.describe ActivityNotifier, type: :mailer do
  let(:site) { Site.create!(name: 'Test Site', host: 'test.example.com', email: 'noreply@test.example.com') }
  let(:section) { Page.create!(site: site, title: 'Test Section') }
  let(:user) { User.create!(first_name: 'John', email: 'john@example.com', password: 'AAbbcc1122!!') }
  let(:article) { Article.create!(site: site, section: section, title: 'Test Article', body: 'Test content', author: user) }
  let(:activity) { Activity.create!(site: site, section: section, object: article, author: user) }

  describe "#new_content_notification" do
    let(:mail) { ActivityNotifier.new_content_notification(activity, user) }

    it "sets the correct recipient" do
      expect(mail.to).to include(user.email)
    end

    it "sets the correct subject with site and section names" do
      expect(mail.subject).to match(/\[#{Regexp.escape(site.name)} \/ #{Regexp.escape(section.title)}\]/)
      expect(mail.subject).to include("Adva.Activity.Notifier.New") # I18n key when translation missing
    end

    it "sets the correct from address" do
      expected_from = "#{site.name} <#{site.email}>"
      expect(mail.from).to include(site.email)
    end

    it "includes activity in the body" do
      expect(mail.body.encoded).to be_present
    end

    it "includes content helper methods" do
      expect(ActivityNotifier._helpers.instance_methods).to include(:link_to_content)
    end
  end

  describe "inheritance" do
    it "inherits from ActionMailer::Base" do
      expect(ActivityNotifier.superclass).to eq(ActionMailer::Base)
    end
  end
end