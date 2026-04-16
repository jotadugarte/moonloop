# frozen_string_literal: true

# Roadmap #10 / REQ-HAB-005: `weekly` is removed; legacy rows become `weekdays` with a one-element array.
#
# Mapping for each former `weekly` row (first match wins):
# 1. First integer in 0..6 from `frequency_params["weekdays"]` if present.
# 2. Else `frequency_params["weekday"]` if it is an integer in 0..6.
# 3. Else `activation_date.wday` if `activation_date` is set.
# 4. Else 0 (Sunday) — counted as fallback; see migration log output.
class MigrateWeeklyUserHabitsToWeekdays < ActiveRecord::Migration[8.1]
  class UserHabit < ActiveRecord::Base
    self.table_name = "user_habits"
  end

  def up
    scope = UserHabit.where(frequency_type: "weekly")
    weekly_count = scope.count
    return if weekly_count.zero?

    fallback_rows = 0
    scope.find_each do |row|
      params = row.frequency_params
      params = {} unless params.is_a?(Hash)
      result = Habits::LegacyWeeklyWeekdayResolver.call(params, row.activation_date)
      fallback_rows += 1 if result.used_fallback
      new_params = params.stringify_keys.merge("weekdays" => [ result.wday ])
      row.update_columns(frequency_type: "weekdays", frequency_params: new_params, updated_at: Time.current)
    end

    say "MigrateWeeklyUserHabitsToWeekdays: migrated #{weekly_count} weekly row(s)."
    if fallback_rows.positive?
      say "  #{fallback_rows} row(s) used default weekday 0 (Sunday) — verify legacy data."
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "weekly frequency_type was removed; restore from backup if needed"
  end
end
