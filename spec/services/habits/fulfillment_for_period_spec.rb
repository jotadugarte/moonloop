# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::FulfillmentForPeriod do
  let(:user) { create(:user, timezone: "Etc/UTC") }
  let(:week) { Date.new(2026, 4, 13)..Date.new(2026, 4, 19) }

  describe ".call" do
    # [REQ-RPT-001]
    it "counts due days, done only for status done, and derives a rounded percentage" do
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1))

      create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 13), status: "done")
      create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 15), status: "failed")

      stats = described_class.call(user_habit: habit, range: week)

      expect(stats.due_count).to eq(7)
      expect(stats.done_count).to eq(1)
      expect(stats.percentage).to eq(14)
    end

    # [REQ-RPT-001]
    it "returns nil for an inactive habit with no completions in the range" do
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1),
        active: false)

      expect(described_class.call(user_habit: habit, range: week)).to be_nil
    end

    # [REQ-RPT-001]
    it "includes an inactive habit when at least one completion exists in the range" do
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1),
        active: true)

      create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 15), status: "done")
      habit.update!(active: false)

      stats = described_class.call(user_habit: habit, range: week)

      expect(stats).to be_present
      expect(stats.due_count).to eq(7)
      expect(stats.done_count).to eq(1)
      expect(stats.percentage).to eq(14)
    end

    # [REQ-RPT-001]
    it "accepts a preloaded completions_by_date map" do
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1))

      d = Date.new(2026, 4, 14)
      row = create(:habit_completion, user_habit: habit, completed_on: d, status: "done")
      by_date = { d => row }

      stats = described_class.call(user_habit: habit, range: week, completions_by_date: by_date)

      expect(stats.done_count).to eq(1)
    end

    # [REQ-RPT-001]
    it "raises when range start is after range end" do
      habit = create(:user_habit, user: user, frequency_type: "daily", activation_date: Date.new(2026, 4, 1))

      expect do
        described_class.call(user_habit: habit, range: Date.new(2026, 4, 20)..Date.new(2026, 4, 10))
      end.to raise_error(ArgumentError, /range start/)
    end

    # [REQ-RPT-001]
    it "returns nil for percentage when there are zero due days in the range" do
      habit = create(:user_habit,
        user: user,
        frequency_type: "weekdays",
        frequency_params: { "weekdays" => [ 1 ] },
        activation_date: Date.new(2026, 4, 13))

      range_only_sun = Date.new(2026, 4, 19)..Date.new(2026, 4, 19)

      stats = described_class.call(user_habit: habit, range: range_only_sun)

      expect(stats.due_count).to eq(0)
      expect(stats.done_count).to eq(0)
      expect(stats.percentage).to be_nil
    end
  end
end
