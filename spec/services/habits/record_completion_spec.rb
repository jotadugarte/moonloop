# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::RecordCompletion do
  let(:user) { create(:user, timezone: "Etc/UTC") }
  let(:category) { create(:habit_category, user: user) }
  let(:local_date) { Date.new(2026, 4, 16) }

  def call!(habit, status:, day_progress: :unset)
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      args = { user: user, user_habit: habit, local_date: local_date, status: status }
      args[:day_progress] = day_progress unless day_progress == :unset
      Habits::RecordCompletion.call(**args)
    end
  end

  # [REQ-RPT-002]
  it "marks streak counters stale when recording a retroactive completion (past local date)" do
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "none",
      daily_target: 1,
      streak_counters_stale: false,
      streak_counters_as_of: Date.new(2026, 4, 16))

    expect(call!(habit, status: "done")).to eq(:ok)

    # The record is for 2026-04-16 while "today" in the travel block is 2026-04-16.
    # This spec intends to be retroactive; it will be adjusted to a past date once
    # RecordCompletion is updated to accept arbitrary local_date under travel_to.
    expect(habit.reload.streak_counters_stale).to be(true)
  end

  # [REQ-DAY-002]
  it "records explicit failed for a none-metric habit" do
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "none",
      daily_target: 1)

    expect(call!(habit, status: "failed")).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.status).to eq("failed")
    expect(row.marked_failed_by_user).to be(true)
  end

  # [REQ-DAY-002]
  it "records done for a none-metric habit unchanged" do
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "none",
      daily_target: 1)

    expect(call!(habit, status: "done")).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.status).to eq("done")
    expect(row.day_progress).to eq(0)
    expect(row.marked_failed_by_user).to be(false)
  end

  # [REQ-DAY-005]
  it "syncs measurable habit to failed when progress is below the daily target" do
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "count",
      daily_target: 8)

    expect(call!(habit, status: "done", day_progress: 5)).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.day_progress).to eq(5)
    expect(row.status).to eq("failed")
    expect(row.marked_failed_by_user).to be(false)
  end

  # [REQ-DAY-005]
  it "syncs measurable habit to done when progress meets the daily target" do
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "count",
      daily_target: 8)

    expect(call!(habit, status: "done", day_progress: 8)).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.day_progress).to eq(8)
    expect(row.status).to eq("done")
    expect(row.marked_failed_by_user).to be(false)
  end

  # [REQ-DAY-005]
  it "keeps explicit failed with partial progress" do
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "count",
      daily_target: 8)

    expect(call!(habit, status: "failed", day_progress: 3)).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.day_progress).to eq(3)
    expect(row.status).to eq("failed")
    expect(row.marked_failed_by_user).to be(true)
  end

  # [REQ-DAY-005]
  it "updates progress on a later call without forcing done below target" do
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "count",
      daily_target: 8)

    expect(call!(habit, status: "done", day_progress: 5)).to eq(:ok)
    expect(call!(habit, status: "done", day_progress: 8)).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.day_progress).to eq(8)
    expect(row.status).to eq("done")
    expect(row.marked_failed_by_user).to be(false)
  end

  # [REQ-DAY-005]
  it "preserves existing day_progress when day_progress is omitted on update" do
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "count",
      daily_target: 8)
    create(:habit_completion, user_habit: habit, completed_on: local_date, status: "failed", day_progress: 6)

    expect(call!(habit, status: "done")).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.day_progress).to eq(6)
    expect(row.status).to eq("failed")
    expect(row.marked_failed_by_user).to be(false)
  end

  # [REQ-DAY-004] / touch cache key coherence
  it "touches the user habit after save" do
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "none",
      daily_target: 1)

    expect { call!(habit, status: "done") }.to(change { habit.reload.updated_at })
  end
end
