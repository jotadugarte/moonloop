# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::SweepHabitRemindersJob, type: :job do
  # [REQ-HAB-010, REQ-HAB-011]
  it "invokes the per-habit processor for active habits whose reminder slot matches the user's local time" do
    madrid_user = create(:user, timezone: "Europe/Madrid")
    la_user = create(:user, timezone: "America/Los_Angeles")

    madrid_habit =
      create(:user_habit,
        user: madrid_user,
        active: true,
        reminder_enabled: true,
        reminder_time_of_day: "08:30",
        reminder_email: true,
        reminder_web_push: false)

    _la_habit =
      create(:user_habit,
        user: la_user,
        active: true,
        reminder_enabled: true,
        reminder_time_of_day: "08:30",
        reminder_email: true,
        reminder_web_push: false)

    inactive_habit =
      create(:user_habit,
        user: madrid_user,
        active: false,
        reminder_enabled: false,
        reminder_time_of_day: nil,
        reminder_email: false,
        reminder_web_push: false)

    allow(Habits::ProcessHabitReminderForUserHabit).to receive(:call)

    travel_to(ActiveSupport::TimeZone["Europe/Madrid"].local(2026, 6, 2, 8, 30, 0)) do
      described_class.perform_now
    end

    expect(Habits::ProcessHabitReminderForUserHabit).to have_received(:call).with(user_habit: madrid_habit)
    expect(Habits::ProcessHabitReminderForUserHabit).not_to have_received(:call).with(user_habit: inactive_habit)
  end
end
