# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::ClearCompletion do
  let(:user) { create(:user, timezone: "Etc/UTC") }
  let(:category) { create(:habit_category, user: user) }

  # [REQ-RPT-002]
  it "marks streak counters stale when clearing a retroactive completion (past local date)" do
    now = Time.utc(2026, 4, 20, 12, 0, 0)
    retro_date = Date.new(2026, 4, 16)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "none",
      daily_target: 1,
      streak_counters_stale: false,
      streak_counters_as_of: Date.new(2026, 4, 20))
    completion = create(:habit_completion, user_habit: habit, completed_on: retro_date, status: "done")

    travel_to now do
      expect(described_class.call(user: user, habit_completion: completion)).to eq(:ok)
      expect(habit.reload.streak_counters_stale).to be(true)
    end
  end
end

