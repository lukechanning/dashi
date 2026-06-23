require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  around do |example|
    original_kyper_mail_from = ENV["KYPER_MAIL_FROM"]
    original_mailer_from = ENV["MAILER_FROM"]

    example.run
  ensure
    ENV["KYPER_MAIL_FROM"] = original_kyper_mail_from
    ENV["MAILER_FROM"] = original_mailer_from
  end

  it "uses KYPER_MAIL_FROM as the default from address" do
    ENV["KYPER_MAIL_FROM"] = "kyper@example.com"
    ENV["MAILER_FROM"] = "legacy@example.com"

    mail = SessionMailer.magic_link(build(:user), "token")

    expect(mail.from).to eq([ "kyper@example.com" ])
  end

  it "falls back to MAILER_FROM" do
    ENV["KYPER_MAIL_FROM"] = nil
    ENV["MAILER_FROM"] = "legacy@example.com"

    mail = SessionMailer.magic_link(build(:user), "token")

    expect(mail.from).to eq([ "legacy@example.com" ])
  end

  it "uses the default address when no env var is set" do
    ENV["KYPER_MAIL_FROM"] = nil
    ENV["MAILER_FROM"] = nil

    mail = SessionMailer.magic_link(build(:user), "token")

    expect(mail.from).to eq([ "noreply@example.com" ])
  end
end
