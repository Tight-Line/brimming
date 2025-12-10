class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", nil).presence || "noreply@example.com"
  layout "mailer"
end
