# frozen_string_literal: true

require "rails_helper"

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
        completion = create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 19), status: "done")
        idx = { Date.new(2026, 4, 19) => completion }

        expect(Habits::Streak.call(user_habit: habit, as_of: Date.new(2026, 4, 19), completions_by_date: idx)).to eq(1)
        expect(Habits::Streak.call(user_habit: habit, as_of: Date.new(2026, 4, 19))).to eq(1)
      end
    end

    # [REQ-DAY-004]
    it "raises ArgumentError when as_of is after the user's local today" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        expect {
          Habits::Streak.call(user_habit: habit, as_of: Date.new(2026, 4, 21))
        }.to raise_error(ArgumentError, /today/)
      end
    end

    # [REQ-DAY-004]
    it "raises ArgumentError when as_of is before the habit's schedulable window starts" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        expect {
          Habits::Streak.call(user_habit: habit, as_of: Date.new(2025, 12, 15))
        }.to raise_error(ArgumentError, /schedulable|before|window/i)
      end
    end

    # [REQ-DAY-004]
    it "raises ArgumentError when as_of is nil" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      expect {
        Habits::Streak.call(user_habit: habit, as_of: nil)
      }.to raise_error(ArgumentError, /as.of|must be a date/i)
    end
  end
end
