# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::LongestStreak do
  describe ".call" do
    # [REQ-RPT-002]
    it "returns the longest run of consecutive due days marked done" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 10), status: "done")
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 11), status: "done")
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 12), status: "failed")

        (Date.new(2026, 4, 15)..Date.new(2026, 4, 19)).each do |day|
          create(:habit_completion, user_habit: habit, completed_on: day, status: "done")
        end

        expect(described_class.call(user_habit: habit)).to eq(5)
      end
    end

    # [REQ-RPT-002]
    it "does not reset the current run on local today when today is due but still open (not done)" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1))

      travel_to Time.utc(2026, 4, 19, 12, 0, 0) do
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 17), status: "done")
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 18), status: "done")

        expect(described_class.call(user_habit: habit, through_date: Date.new(2026, 4, 19))).to eq(2)
      end
    end

    # [REQ-RPT-002]
    it "extends through local today when today is done" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1))

      travel_to Time.utc(2026, 4, 19, 12, 0, 0) do
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 17), status: "done")
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 18), status: "done")
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 19), status: "done")

        expect(described_class.call(user_habit: habit)).to eq(3)
      end
    end

    # [REQ-RPT-002] [REQ-DAY-005]
    it "counts consecutive measurable days only when each day meets the daily target" do
      user = create(:user, timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1),
        habit_metric_kind: "count",
        daily_target: 4)

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 17), status: "done", day_progress: 4)
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 18), status: "done", day_progress: 4)
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 19), status: "done", day_progress: 2)

        expect(described_class.call(user_habit: habit, through_date: Date.new(2026, 4, 19))).to eq(2)
      end
    end

    # [REQ-RPT-002]
    it "uses schedule_only due checks when the habit is inactive (historical reporting)" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1),
        active: true)

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        (Date.new(2026, 4, 10)..Date.new(2026, 4, 12)).each do |day|
          create(:habit_completion, user_habit: habit, completed_on: day, status: "done")
        end
        habit.update!(active: false)

        expect(described_class.call(user_habit: habit)).to eq(3)
      end
    end

    # [REQ-RPT-002]
    it "accepts a preloaded completions_by_date map" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1))

      travel_to Time.utc(2026, 4, 14, 12, 0, 0) do
        d = Date.new(2026, 4, 13)
        row = create(:habit_completion, user_habit: habit, completed_on: d, status: "done")
        idx = { d => row }

        expect(described_class.call(user_habit: habit, through_date: d, completions_by_date: idx)).to eq(1)
      end
    end

    # [REQ-RPT-002]
    it "raises when through_date is after the user's local today" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1))

      travel_to Time.utc(2026, 4, 19, 12, 0, 0) do
        expect do
          described_class.call(user_habit: habit, through_date: Date.new(2026, 4, 20))
        end.to raise_error(ArgumentError, /today/)
      end
    end

    # [REQ-RPT-002]
    it "raises when the inclusive calendar span exceeds the safety limit" do
      stub_const("Habits::Streak::MAX_CALENDAR_DAY_STEPS", 3)

      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1))

      travel_to Time.utc(2026, 4, 5, 12, 0, 0) do
        expect do
          described_class.call(user_habit: habit, through_date: Date.new(2026, 4, 4))
        end.to raise_error(ArgumentError, /exceeded 3 calendar days/)
      end
    end
  end
end
