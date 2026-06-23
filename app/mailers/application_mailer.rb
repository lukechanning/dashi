class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV["KYPER_MAIL_FROM"].presence || ENV["MAILER_FROM"].presence || "noreply@example.com" }
  layout "mailer"
end
