require "rails_helper"

RSpec.describe HabitReminderEvent, type: :model do
  describe "associations" do
    # [REQ-HAB-011]
    it { should belong_to(:user) }
    # [REQ-HAB-011]
    it { should belong_to(:user_habit) }
  end

  describe "validations" do
    subject(:event) { create(:habit_reminder_event) }

    # [REQ-HAB-011]
    it { should validate_presence_of(:local_date) }

    # [REQ-HAB-011]
    it "is idempotent per user, habit, and local_date" do
      existing = create(:habit_reminder_event)

      dupe = build(:habit_reminder_event,
        user: existing.user,
        user_habit: existing.user_habit,
        local_date: existing.local_date)

      expect(dupe).not_to be_valid
    end
  end
end

