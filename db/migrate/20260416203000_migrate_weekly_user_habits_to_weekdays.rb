# frozen_string_literal: true

# Roadmap #10 / REQ-HAB-005: `weekly` is removed; legacy rows become `weekdays` with a one-element array.
#
# Mapping for each former `weekly` row (first match wins):
# 1. First integer in 0..6 from `frequency_params["weekdays"]` if present.
# 2. Else `frequency_params["weekday"]` if it is an integer in 0..6.
# 3. Else `activation_date.wday` if `activation_date` is set.
# 4. Else 0 (Sunday).
class MigrateWeeklyUserHabitsToWeekdays < ActiveRecord::Migration[8.1]
  class UserHabit < ActiveRecord::Base
    self.table_name = "user_habits"
  end

  def up
    UserHabit.where(frequency_type: "weekly").find_each do |row|
      params = row.frequency_params
      params = {} unless params.is_a?(Hash)
      wday = wday_from_legacy_weekly(params, row.activation_date)
      new_params = params.stringify_keys.merge("weekdays" => [wday])
      row.update_columns(frequency_type: "weekdays", frequency_params: new_params, updated_at: Time.current)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "weekly frequency_type was removed; restore from backup if needed"
  end

  private

  def wday_from_legacy_weekly(params, activation_date)
    raw_weekdays = params["weekdays"] || params[:weekdays]
    if raw_weekdays.is_a?(Array)
      raw_weekdays.each do |v|
        i = v.is_a?(Integer) ? v : Integer(v, exception: false)
        return i if i.is_a?(Integer) && i.between?(0, 6)
      end
    end

    single = params["weekday"] || params[:weekday]
    if single.is_a?(Integer) && single.between?(0, 6)
      return single
    end
    if single.present?
      i = Integer(single, exception: false)
      return i if i.is_a?(Integer) && i.between?(0, 6)
    end

    return activation_date.wday if activation_date.respond_to?(:wday) && activation_date.present?

    0
  end
end
