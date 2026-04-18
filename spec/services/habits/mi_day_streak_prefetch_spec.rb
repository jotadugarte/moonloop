# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::MiDayStreakPrefetch do
  # Oracle: mirrors MyDayController#streak_completions_indexed_by_date + #streaks_for_due_habits.
  def streak_by_habit_id_like_controller(due_habits, local_date)
    return {} if due_habits.empty?

    lowers = due_habits.map { |h| Habits::Streak.lower_bound_for(h) }
    from = lowers.min
    habit_ids = due_habits.map(&:id)

    by_habit = HabitCompletion
      .where(user_habit_id: habit_ids, completed_on: from..local_date)
      .group_by(&:user_habit_id)
      .transform_values { |rows| rows.index_by(&:completed_on) }

    due_habits.each_with_object({}) do |habit, acc|
      acc[habit.id] = Habits::Streak.call(
        user_habit: habit,
        as_of: local_date,
        completions_by_date: by_habit[habit.id] || {}
      )
    end
  end

  describe ".call" do
    # [REQ-DAY-004]
    it "matches controller streak map for a long run of consecutive done days" do
      user = create(:user, timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        local_date = Date.new(2026, 4, 19)
        (Date.new(2026, 3, 20)..local_date).each do |d|
          create(:habit_completion, user_habit: habit, completed_on: d, status: "done")
        end

        due = Habits::DueHabitsForDay.call(user: user, local_date: local_date)
        expected = streak_by_habit_id_like_controller(due, local_date)

        result = described_class.call(user: user, due_habits: due, local_date: local_date)
        expect(result).to eq(expected)
        expect(result[habit.id]).to eq(31)
      end
    end

    # [REQ-DAY-004]
    it "matches controller streak map when only some due habits have completions" do
      user = create(:user, timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      done_habit = create(:user_habit,
        user: user,
        habit_category: category,
        name: "Siempre hecho",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))
      bare_habit = create(:user_habit,
        user: user,
        habit_category: category,
        name: "Sin marcar",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        local_date = Date.new(2026, 4, 19)
        create(:habit_completion, user_habit: done_habit, completed_on: local_date, status: "done")

        due = Habits::DueHabitsForDay.call(user: user, local_date: local_date)
        expected = streak_by_habit_id_like_controller(due, local_date)

        result = described_class.call(user: user, due_habits: due, local_date: local_date)
        expect(result).to eq(expected)
        expect(result[bare_habit.id]).to eq(0)
        expect(result[done_habit.id]).to eq(1)
      end
    end

    # [REQ-DAY-004]
    it "only includes streaks for habits in the due list (inactive habits never appear)" do
      user = create(:user, timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      active = create(:user_habit,
        user: user,
        habit_category: category,
        name: "Activo",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))
      create(:user_habit,
        user: user,
        habit_category: category,
        name: "Inactivo",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1),
        active: false)

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        local_date = Date.new(2026, 4, 19)
        create(:habit_completion, user_habit: active, completed_on: local_date, status: "done")

        due = Habits::DueHabitsForDay.call(user: user, local_date: local_date)
        expect(due.map(&:name)).to eq([ "Activo" ])

        expected = streak_by_habit_id_like_controller(due, local_date)
        result = described_class.call(user: user, due_habits: due, local_date: local_date)

        expect(result).to eq(expected)
        expect(result.keys).to eq([ active.id ])
      end
    end

    # [REQ-DAY-004]
    it "returns an empty hash when no habits are due" do
      user = create(:user, timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      create(:user_habit,
        user: user,
        habit_category: category,
        name: "Solo Lun",
        frequency_type: "weekdays",
        frequency_params: { "weekdays" => [ 1 ] },
        activation_date: Date.new(2026, 1, 1))

      travel_to Time.utc(2026, 4, 16, 12, 0, 0) do # Thursday
        local_date = Date.new(2026, 4, 16)
        due = Habits::DueHabitsForDay.call(user: user, local_date: local_date)
        expect(due).to be_empty

        result = described_class.call(user: user, due_habits: due, local_date: local_date)
        expect(result).to eq({})
      end
    end
  end
end
