# frozen_string_literal: true

require "rails_helper"

# Next: implement Habits::Streak to satisfy REQ-DAY-004 (minimal API TBD by examples).
RSpec.describe "Habits::Streak" do
  describe ".call" do
    # [REQ-DAY-004]
    it "returns 0 when there are no done completions before as_of" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        result = Habits::Streak.call(user_habit: habit, as_of: Date.new(2026, 4, 19))
        expect(result).to eq(0)
      end
    end

    # [REQ-DAY-004]
    it "returns 1 when only the streak-ending closed due day is done" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 19), status: "done")

        result = Habits::Streak.call(user_habit: habit, as_of: Date.new(2026, 4, 19))
        expect(result).to eq(1)
      end
    end
  end
end
