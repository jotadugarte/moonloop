# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::ProcessHabitReminderForUserHabit do
  let(:user) { create(:user, timezone: "Europe/Madrid") }
  let(:category) { create(:habit_category, user: user) }
  let(:habit) do
    create(:user_habit,
      user: user,
      habit_category: category,
      active: true,
      frequency_type: "daily",
      frequency_params: {},
      reminder_enabled: true,
      reminder_time_of_day: "08:30",
      reminder_email: true,
      reminder_web_push: false)
  end

  before { ActionMailer::Base.deliveries.clear }

  # [REQ-HAB-013]
  it "creates one event and sends one email when reminder_email is enabled" do
    madrid = ActiveSupport::TimeZone["Europe/Madrid"].local(2026, 6, 2, 8, 30, 0)
    travel_to(madrid) do
      reloaded = habit.reload
      expect(HabitReminderMailer).to receive(:notify).with(user: user, user_habit: reloaded).and_call_original

      expect {
        described_class.call(user_habit: reloaded)
      }.to change(HabitReminderEvent, :count).by(1)
        .and change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end

  # [REQ-HAB-013]
  it "creates an event but skips email when reminder_email is disabled" do
    habit.update!(reminder_email: false)
    madrid = ActiveSupport::TimeZone["Europe/Madrid"].local(2026, 6, 2, 8, 30, 0)
    travel_to(madrid) do
      expect {
        described_class.call(user_habit: habit.reload)
      }.to change(HabitReminderEvent, :count).by(1)
    end
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  # [REQ-HAB-010, REQ-HAB-011]
  it "creates a HabitReminderEvent when processing the reminder for that local day" do
    madrid = ActiveSupport::TimeZone["Europe/Madrid"].local(2026, 6, 2, 8, 30, 0)
    travel_to(madrid) do
      expect {
        described_class.call(user_habit: habit.reload)
      }.to change(HabitReminderEvent, :count).by(1)
    end
  end

  # [REQ-HAB-013]
  it "does not create an event when the habit is already done for the user-local day" do
    madrid = ActiveSupport::TimeZone["Europe/Madrid"].local(2026, 6, 2, 8, 30, 0)
    travel_to(madrid) do
      Habits::RecordCompletion.call(
        user: user,
        user_habit: habit.reload,
        local_date: madrid.to_date,
        status: "done"
      )

      expect {
        described_class.call(user_habit: habit.reload)
      }.not_to change(HabitReminderEvent, :count)
    end
  end
end
