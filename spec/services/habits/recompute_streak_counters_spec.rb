# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::RecomputeStreakCounters do
  let(:user) { create(:user, timezone: "Etc/UTC") }
  let(:category) { create(:habit_category, user: user) }

  # [REQ-RPT-002]
  it "writes current and longest streak counters through today and clears stale" do
    now = Time.utc(2026, 4, 20, 12, 0, 0)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 4, 1),
      habit_metric_kind: "none",
      daily_target: 1,
      streak_counters_stale: true,
      streak_counters_as_of: nil,
      current_streak_today: 0,
      longest_streak_through_today: 0)

    travel_to now do
      create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 18), status: "done")
      create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 19), status: "done")

      described_class.call(user_habit: habit)

      habit.reload
      expect(habit.streak_counters_stale).to be(false)
      expect(habit.streak_counters_as_of).to eq(Date.new(2026, 4, 20))
      expect(habit.current_streak_today).to eq(2)
      expect(habit.longest_streak_through_today).to eq(2)
    end
  end
end

