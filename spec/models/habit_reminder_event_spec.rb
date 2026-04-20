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
    it "rejects duplicate rows per user, habit, and local_date at the database" do
      existing = create(:habit_reminder_event)

      dupe = build(:habit_reminder_event,
        user: existing.user,
        user_habit: existing.user_habit,
        local_date: existing.local_date)

      expect(dupe).to be_valid
      expect { dupe.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
