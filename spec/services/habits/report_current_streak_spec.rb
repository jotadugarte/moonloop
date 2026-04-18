# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::ReportCurrentStreak do
  describe ".call" do
    # [REQ-RPT-002]
    it "returns the same value as Habits::Streak.call with preloaded completions_by_date (Mi Día pattern)" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        d1 = Date.new(2026, 4, 18)
        d2 = Date.new(2026, 4, 19)
        c1 = create(:habit_completion, user_habit: habit, completed_on: d1, status: "done")
        c2 = create(:habit_completion, user_habit: habit, completed_on: d2, status: "done")
        idx = { d1 => c1, d2 => c2 }
        as_of = Date.new(2026, 4, 19)

        from_streak = Habits::Streak.call(user_habit: habit, as_of: as_of, completions_by_date: idx)
        from_report = described_class.call(user_habit: habit, as_of: as_of, completions_by_date: idx)

        expect(from_report).to eq(from_streak)
        expect(from_report).to eq(2)
      end
    end

    # [REQ-RPT-002]
    it "matches Habits::Streak.call when completions are loaded per row (no preload)" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 19), status: "done")
        as_of = Date.new(2026, 4, 19)

        expect(described_class.call(user_habit: habit, as_of: as_of)).to eq(
          Habits::Streak.call(user_habit: habit, as_of: as_of)
        )
      end
    end

    # [REQ-RPT-002]
    it "matches Habits::Streak.call for an inactive habit (both return 0)" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1),
        active: false)

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        as_of = Date.new(2026, 4, 19)
        report = described_class.call(user_habit: habit, as_of: as_of)
        streak = Habits::Streak.call(user_habit: habit, as_of: as_of)

        expect(report).to eq(streak)
        expect(report).to eq(0)
      end
    end

    # [REQ-RPT-002]
    it "propagates the same ArgumentError as Habits::Streak for future as_of" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1))

      travel_to Time.utc(2026, 4, 19, 12, 0, 0) do
        expect { Habits::Streak.call(user_habit: habit, as_of: Date.new(2026, 4, 20)) }.to raise_error(ArgumentError)
        expect { described_class.call(user_habit: habit, as_of: Date.new(2026, 4, 20)) }.to raise_error(ArgumentError)
      end
    end
  end
end
