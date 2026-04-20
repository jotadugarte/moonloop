# frozen_string_literal: true

class HabitReminderMailer < ApplicationMailer
  def notify(user:, user_habit:)
    @user = user
    @user_habit = user_habit

    mail(
      to: @user.email,
      subject: I18n.t("habit_reminder_mailer.notify.subject", habit_name: @user_habit.name)
    )
  end
end

