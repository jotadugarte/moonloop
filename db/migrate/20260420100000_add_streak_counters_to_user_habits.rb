# frozen_string_literal: true

class AddStreakCountersToUserHabits < ActiveRecord::Migration[8.1]
  def change
    add_column :user_habits, :current_streak_today, :integer, null: false, default: 0
    add_column :user_habits, :longest_streak_through_today, :integer, null: false, default: 0
    add_column :user_habits, :streak_counters_as_of, :date
    add_column :user_habits, :streak_counters_stale, :boolean, null: false, default: true

    add_index :user_habits, [ :streak_counters_stale, :streak_counters_as_of ],
      name: "index_user_habits_on_streak_counters_freshness"
  end
end
