# frozen_string_literal: true

# Roadmap #10 / REQ-HAB-005: `weekly` is removed; legacy rows become `weekdays` with a one-element array.
#
# Mapping for each former `weekly` row (first match wins):
# 1. First integer in 0..6 from `frequency_params["weekdays"]` if present.
# 2. Else `frequency_params["weekday"]` if it is an integer in 0..6.
# 3. Else `activation_date.wday` if `activation_date` is set.
# 4. Else 0 (Sunday) — counted as fallback; see migration log output.
#
# WdayResolver below is intentionally **duplicated** (not `require` of app code) so this
# migration stays immutable if `Habits::LegacyWeeklyWeekdayResolver` changes later.
# Specs exercise the app copy; keep behavior in sync if rules ever change.
class MigrateWeeklyUserHabitsToWeekdays < ActiveRecord::Migration[8.1]
  class UserHabit < ActiveRecord::Base
    self.table_name = "user_habits"
  end

  # Frozen snapshot for this migration only — mirror of Habits::LegacyWeeklyWeekdayResolver.
  class WdayResolver
    Result = Struct.new(:wday, :used_fallback, keyword_init: true)

    def self.call(params, activation_date)
      new(params, activation_date).send(:resolve)
    end

    def initialize(params, activation_date)
      @params = params.is_a?(Hash) ? params : {}
      @activation_date = activation_date
    end

    private_class_method :new

    private

    def resolve
      wday = wday_from_weekdays_array
      return ok(wday) unless wday.nil?

      wday = wday_from_weekday_param
      return ok(wday) unless wday.nil?

      wday = wday_from_activation
      return ok(wday) unless wday.nil?

      Result.new(wday: 0, used_fallback: true)
    end

    def ok(wday)
      Result.new(wday: wday, used_fallback: false)
    end

    def wday_from_weekdays_array
      raw = @params["weekdays"] || @params[:weekdays]
      return nil unless raw.is_a?(Array)

      raw.each do |v|
        i = coerce_day_index(v)
        return i unless i.nil?
      end
      nil
    end

    def wday_from_weekday_param
      single = @params["weekday"] || @params[:weekday]
      return nil if single.blank?

      coerce_day_index(single)
    end

    def wday_from_activation
      return nil unless @activation_date.respond_to?(:wday)
      return nil if @activation_date.blank?

      @activation_date.wday
    end

    def coerce_day_index(value)
      return value if value.is_a?(Integer) && value.between?(0, 6)

      i = Integer(value, exception: false)
      return i if i.is_a?(Integer) && i.between?(0, 6)

      nil
    end
  end

  def up
    scope = UserHabit.where(frequency_type: "weekly")
    weekly_count = scope.count
    return if weekly_count.zero?

    fallback_rows = 0
    scope.find_each do |row|
      params = row.frequency_params
      params = {} unless params.is_a?(Hash)
      result = WdayResolver.call(params, row.activation_date)
      fallback_rows += 1 if result.used_fallback
      new_params = params.stringify_keys.merge("weekdays" => [ result.wday ])
      row.update_columns(frequency_type: "weekdays", frequency_params: new_params, updated_at: Time.current)
    end

    say "MigrateWeeklyUserHabitsToWeekdays: migrated #{weekly_count} weekly row(s)."
    if fallback_rows.positive?
      say "  #{fallback_rows} row(s) used default weekday 0 (Sunday) — verify legacy data."
    end
  end

  # Irreversible: `weekly` was removed from the domain model; rollback requires a DB backup
  # and manual restore — see message below.
  def down
    raise ActiveRecord::IrreversibleMigration,
          "weekly frequency_type was removed; restore from backup if needed"
  end
end
