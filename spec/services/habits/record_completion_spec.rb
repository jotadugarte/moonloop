# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::RecordCompletion do
  include ActiveJob::TestHelper

  let(:user) { create(:user, timezone: "Etc/UTC") }
  let(:category) { create(:habit_category, user: user) }

  def call!(habit, now:, local_date:, status:, day_progress: :unset)
    travel_to now do
      args = { user: user, user_habit: habit, local_date: local_date, status: status }
      args[:day_progress] = day_progress unless day_progress == :unset
      Habits::RecordCompletion.call(**args)
    end
  end

  # [REQ-RPT-002]
  it "marks streak counters stale when recording a retroactive completion (past local date)" do
    retro_date = Date.new(2026, 4, 16)
    now = Time.utc(2026, 4, 20, 12, 0, 0)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "none",
      daily_target: 1,
      streak_counters_stale: false,
      streak_counters_as_of: Date.new(2026, 4, 20))

    expect {
      expect(call!(habit, now: now, local_date: retro_date, status: "done")).to eq(:ok)
    }.to have_enqueued_job(Habits::RecomputeStreakCountersJob).with(user_habit_id: habit.id)
    expect(habit.reload.streak_counters_stale).to be(true)
  end

  # [REQ-RPT-002]
  it "recomputes streak counters when recording a completion for today" do
    today = Date.new(2026, 4, 20)
    now = Time.utc(2026, 4, 20, 12, 0, 0)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "none",
      daily_target: 1,
      streak_counters_stale: true,
      streak_counters_as_of: nil)

    allow(Habits::RecomputeStreakCounters).to receive(:call).and_call_original

    expect(call!(habit, now: now, local_date: today, status: "done")).to eq(:ok)

    expect(Habits::RecomputeStreakCounters).to have_received(:call).with(user_habit: habit)
    habit.reload
    expect(habit.streak_counters_stale).to be(false)
    expect(habit.streak_counters_as_of).to eq(today)
  end

  # [REQ-DAY-002]
  it "records explicit failed for a none-metric habit" do
    local_date = Date.new(2026, 4, 16)
    now = Time.utc(2026, 4, 16, 12, 0, 0)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "none",
      daily_target: 1)

    expect(call!(habit, now: now, local_date: local_date, status: "failed")).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.status).to eq("failed")
    expect(row.marked_failed_by_user).to be(true)
  end

  # [REQ-DAY-002]
  it "records done for a none-metric habit unchanged" do
    local_date = Date.new(2026, 4, 16)
    now = Time.utc(2026, 4, 16, 12, 0, 0)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "none",
      daily_target: 1)

    expect(call!(habit, now: now, local_date: local_date, status: "done")).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.status).to eq("done")
    expect(row.day_progress).to eq(0)
    expect(row.marked_failed_by_user).to be(false)
  end

  # [REQ-DAY-005]
  it "syncs measurable habit to failed when progress is below the daily target" do
    local_date = Date.new(2026, 4, 16)
    now = Time.utc(2026, 4, 16, 12, 0, 0)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "count",
      daily_target: 8)

    expect(call!(habit, now: now, local_date: local_date, status: "done", day_progress: 5)).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.day_progress).to eq(5)
    expect(row.status).to eq("failed")
    expect(row.marked_failed_by_user).to be(false)
  end

  # [REQ-DAY-005]
  it "syncs measurable habit to done when progress meets the daily target" do
    local_date = Date.new(2026, 4, 16)
    now = Time.utc(2026, 4, 16, 12, 0, 0)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "count",
      daily_target: 8)

    expect(call!(habit, now: now, local_date: local_date, status: "done", day_progress: 8)).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.day_progress).to eq(8)
    expect(row.status).to eq("done")
    expect(row.marked_failed_by_user).to be(false)
  end

  # [REQ-DAY-005]
  it "keeps explicit failed with partial progress" do
    local_date = Date.new(2026, 4, 16)
    now = Time.utc(2026, 4, 16, 12, 0, 0)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "count",
      daily_target: 8)

    expect(call!(habit, now: now, local_date: local_date, status: "failed", day_progress: 3)).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.day_progress).to eq(3)
    expect(row.status).to eq("failed")
    expect(row.marked_failed_by_user).to be(true)
  end

  # [REQ-DAY-005]
  it "updates progress on a later call without forcing done below target" do
    local_date = Date.new(2026, 4, 16)
    now = Time.utc(2026, 4, 16, 12, 0, 0)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "count",
      daily_target: 8)

    expect(call!(habit, now: now, local_date: local_date, status: "done", day_progress: 5)).to eq(:ok)
    expect(call!(habit, now: now, local_date: local_date, status: "done", day_progress: 8)).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.day_progress).to eq(8)
    expect(row.status).to eq("done")
    expect(row.marked_failed_by_user).to be(false)
  end

  # [REQ-DAY-005]
  it "preserves existing day_progress when day_progress is omitted on update" do
    local_date = Date.new(2026, 4, 16)
    now = Time.utc(2026, 4, 16, 12, 0, 0)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "count",
      daily_target: 8)
    create(:habit_completion, user_habit: habit, completed_on: local_date, status: "failed", day_progress: 6)

    expect(call!(habit, now: now, local_date: local_date, status: "done")).to eq(:ok)
    row = HabitCompletion.find_by!(user_habit: habit, completed_on: local_date)
    expect(row.day_progress).to eq(6)
    expect(row.status).to eq("failed")
    expect(row.marked_failed_by_user).to be(false)
  end

  # [REQ-DAY-004] / touch cache key coherence
  it "touches the user habit after save" do
    local_date = Date.new(2026, 4, 16)
    now = Time.utc(2026, 4, 16, 12, 0, 0)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      frequency_type: "daily",
      activation_date: Date.new(2026, 1, 1),
      habit_metric_kind: "none",
      daily_target: 1)

    expect { call!(habit, now: now, local_date: local_date, status: "done") }.to(change { habit.reload.updated_at })
  end
end
