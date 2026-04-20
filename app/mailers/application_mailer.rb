class ApplicationMailer < ActionMailer::Base
  # REQ-PROF-003 / mailers: use BodyMetricsHelper (format_body_weight, format_body_height_snapshot)
  # in templates — never render canonical kg/cm columns directly.
  helper BodyMetricsHelper

  default from: "from@example.com"
  layout "mailer"
end
