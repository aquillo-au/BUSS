class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "aquillosalt@gmail.com")
  layout "mailer"
end
