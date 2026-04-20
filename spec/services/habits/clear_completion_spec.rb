# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::ClearCompletion do
  include ActiveJob::TestHelper

  let(:user) { create(:user, timezone: "Etc/UTC") }
  let(:category) { create(:habit_category, user: user) }

  # [REQ-RPT-002]
  it "recomputes streak counters when clearing a completion for today" do
    now = Time.utc(2026, 4, 20, 12, 0, 0)
    today = Date.new(2026, 4, 20)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "none",
      daily_target: 1,
      streak_counters_stale: true,
      streak_counters_as_of: nil)
    completion = create(:habit_completion, user_habit: habit, completed_on: today, status: "done")

    allow(Habits::RecomputeStreakCounters).to receive(:call).and_call_original

    travel_to now do
      expect(described_class.call(user: user, habit_completion: completion)).to eq(:ok)
    end

    expect(Habits::RecomputeStreakCounters).to have_received(:call).with(user_habit: habit)
    habit.reload
    expect(habit.streak_counters_stale).to be(false)
    expect(habit.streak_counters_as_of).to eq(today)
  end

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
      expect {
        expect(described_class.call(user: user, habit_completion: completion)).to eq(:ok)
      }.to have_enqueued_job(Habits::RecomputeStreakCountersJob).with(user_habit_id: habit.id)
      expect(habit.reload.streak_counters_stale).to be(true)
    end
  end
end
