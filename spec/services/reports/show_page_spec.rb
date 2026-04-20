# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::ShowPage do
  let(:password) { "Password123!" }
  let(:user) { create(:user, password: password, timezone: "Etc/UTC") }

  describe ".call" do
    # [REQ-RPT-002]
    it "uses persisted streak counters for today when they are fresh and not stale" do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1),
        active: true,
        current_streak_today: 7,
        longest_streak_through_today: 21,
        streak_counters_as_of: Date.new(2026, 4, 20),
        streak_counters_stale: false)

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        # If the implementation incorrectly falls back to live computation,
        # these stubs will be invoked and fail the example.
        allow(Habits::ReportCurrentStreak).to receive(:call).and_raise("should use persisted counters for today")
        allow(Habits::LongestStreak).to receive(:call).and_raise("should use persisted counters for today")

        result = described_class.call(user: user, fecha_param: "2026-04-20")
        expect(result.redirect_alert).to be_nil

        row = result.assigns[:streak_rows].find { |r| r[:habit].id == habit.id }
        expect(row).to be_present
        expect(row[:current]).to eq(7)
        expect(row[:longest]).to eq(21)
      end
    end

    # [REQ-RPT-002]
    it "omits an inactive habit from streak rows when it has no completions in the week–month window" do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 3, 1),
        active: true)

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 3, 10), status: "done")
        habit.update!(active: false)

        result = described_class.call(user: user, fecha_param: "2026-04-15")
        expect(result.redirect_alert).to be_nil

        names = result.assigns[:streak_rows].map { |r| r[:habit].name }
        expect(names).not_to include(habit.name)
      end
    end

    # [REQ-RPT-002]
    it "includes an inactive habit in streak rows when it has a completion in the week–month window" do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 3, 1),
        active: true)

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 14), status: "done")
        habit.update!(active: false)

        result = described_class.call(user: user, fecha_param: "2026-04-15")
        names = result.assigns[:streak_rows].map { |r| r[:habit].name }
        expect(names).to include(habit.name)
      end
    end

    # [REQ-RPT-001, REQ-RPT-002, REQ-RPT-003]
    it "returns a flash alert for an invalid fecha" do
      result = described_class.call(user: user, fecha_param: "nope")
      expect(result.redirect_alert).to eq(I18n.t("reports.flash.invalid_date"))
      expect(result.assigns).to be_nil
    end
  end
end
