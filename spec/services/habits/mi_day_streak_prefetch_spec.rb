# frozen_string_literal: true

require "rails_helper"

# String describe: constant may not exist yet (TDD red); resolution happens inside examples.
RSpec.describe "Habits::MiDayStreakPrefetch" do
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

  # SELECTs only — ignores INSERT/UPDATE during setup.
  def habit_completion_select_sqls
    sqls = []
    subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      next if payload[:cached]

      sql = payload[:sql].to_s
      next unless sql.match?(/\bFROM\s+[`"]?habit_completions[`"]?/i)

      sqls << sql
    end
    yield
    sqls
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
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

        result = Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)
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

        result = Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)
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
        result = Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)

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

        result = Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)
        expect(result).to eq({})
      end
    end
  end

  describe "prefetch query contract" do
    # [REQ-DAY-004]
    it "uses a single SELECT from habit_completions for all due habits" do
      user = create(:user, timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      a = create(:user_habit,
        user: user,
        habit_category: category,
        name: "A",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))
      b = create(:user_habit,
        user: user,
        habit_category: category,
        name: "B",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        local_date = Date.new(2026, 4, 19)
        5.times do |i|
          create(:habit_completion, user_habit: a, completed_on: local_date - i, status: "done")
          create(:habit_completion, user_habit: b, completed_on: local_date - i, status: "done")
        end

        due = Habits::DueHabitsForDay.call(user: user, local_date: local_date)

        sqls = habit_completion_select_sqls do
          Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)
        end

        expect(sqls.size).to eq(1)
      end
    end

    # [REQ-DAY-004]
    it "scopes completed_on to the streak window ending at local_date (not later days)" do
      user = create(:user, timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        local_date = Date.new(2026, 4, 10)
        create(:habit_completion, user_habit: habit, completed_on: local_date, status: "done")
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 18), status: "done")

        due = Habits::DueHabitsForDay.call(user: user, local_date: local_date)

        allow(HabitCompletion).to receive(:where).and_wrap_original do |m, *args, **kwargs|
          hash = args.first.is_a?(Hash) ? args.first.merge(kwargs) : kwargs
          if hash[:completed_on].is_a?(Range)
            expect(hash[:completed_on].end).to eq(local_date)
            expect(hash[:completed_on].cover?(Date.new(2026, 4, 18))).to be(false)
          end
          m.call(*args, **kwargs)
        end

        Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)
      end
    end

    # [REQ-DAY-004]
    it "selects only columns needed for streak walks (id, user_habit_id, completed_on, status)" do
      user = create(:user, timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        local_date = Date.new(2026, 4, 19)
        create(:habit_completion, user_habit: habit, completed_on: local_date, status: "done")

        due = Habits::DueHabitsForDay.call(user: user, local_date: local_date)

        sqls = habit_completion_select_sqls do
          Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)
        end

        sql = sqls.join
        expect(sql).to match(/"habit_completions"\."id"/i)
        expect(sql).to match(/"habit_completions"\."user_habit_id"/i)
        expect(sql).to match(/"habit_completions"\."completed_on"/i)
        expect(sql).to match(/"habit_completions"\."status"/i)
        expect(sql).not_to match(/"habit_completions"\."created_at"/i)
        expect(sql).not_to match(/"habit_completions"\."updated_at"/i)
      end
    end

    # [REQ-DAY-004]
    it "keeps a composite index on user_habit_id and completed_on for lookups" do
      names = HabitCompletion.connection.indexes("habit_completions").map(&:name)
      expect(names).to include("index_habit_completions_on_user_habit_and_completed_on")
    end
  end

  describe "caching" do
    around do |example|
      previous = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
    ensure
      Rails.cache = previous
    end

    # [REQ-DAY-004]
    it "does not run a second habit_completions SELECT on cache hit" do
      user = create(:user, timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        local_date = Date.new(2026, 4, 19)
        create(:habit_completion, user_habit: habit, completed_on: local_date, status: "done")

        due = Habits::DueHabitsForDay.call(user: user, local_date: local_date)

        first = habit_completion_select_sqls do
          Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)
        end
        second = habit_completion_select_sqls do
          Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)
        end

        expect(first.size).to eq(1)
        expect(second.size).to eq(0)
      end
    end

    # [REQ-DAY-004]
    it "recomputes after Habits::RecordCompletion updates the streak (cache bust via user_habit touch)" do
      user = create(:user, timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        local_date = Date.new(2026, 4, 19)
        due = Habits::DueHabitsForDay.call(user: user, local_date: local_date)

        expect(Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)[habit.id]).to eq(0)
        Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)

        expect(Habits::RecordCompletion.call(
          user: user,
          user_habit: habit,
          local_date: local_date,
          status: "done"
        )).to eq(:ok)

        expect(Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)[habit.id]).to eq(1)
      end
    end

    # [REQ-DAY-004]
    it "recomputes after Habits::ClearCompletion (cache bust via user_habit touch)" do
      user = create(:user, timezone: "Etc/UTC")
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        local_date = Date.new(2026, 4, 19)
        row = create(:habit_completion, user_habit: habit, completed_on: local_date, status: "done")
        due = Habits::DueHabitsForDay.call(user: user, local_date: local_date)

        Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)
        expect(Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)[habit.id]).to eq(1)

        expect(Habits::ClearCompletion.call(user: user, habit_completion: row)).to eq(:ok)

        expect(Habits::MiDayStreakPrefetch.call(user: user, due_habits: due, local_date: local_date)[habit.id]).to eq(0)
      end
    end
  end
end
