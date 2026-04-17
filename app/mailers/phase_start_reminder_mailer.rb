# frozen_string_literal: true

class PhaseStartReminderMailer < ApplicationMailer
  def notify(user)
    @user = user
    mail(
      to: @user.email,
      subject: I18n.t("phase_start_reminder_mailer.notify.subject")
    )
  end
end
