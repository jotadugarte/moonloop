module Habits
  # Computes the next calendar occurrence after +date+ for preview/tests.
  # +weekdays+ and +every_x_days+ follow the same calendar rules as +Habits::DueOnDate+.
  class NextOccurrence
    def self.after(user_habit:, date:)
      raise ArgumentError unless date.is_a?(Date)

      case user_habit.frequency_type
      when "daily"
        date + 1.day
      when "weekdays"
        weekdays = normalized_weekdays(user_habit)
        raise ArgumentError if weekdays.empty?

        1.upto(7) do |offset|
          candidate = date + offset
          return candidate if weekdays.include?(candidate.wday)
        end

        raise ArgumentError, "no next weekday in range"
      when "every_x_days"
        act = user_habit.activation_date
        raise ArgumentError if act.blank?

        interval = user_habit.frequency_params.is_a?(Hash) ? user_habit.frequency_params["interval"] : nil
        raise ArgumentError unless interval.is_a?(Integer) && interval >= 1

        candidate = date + 1.day
        400.times do
          return candidate if candidate >= act && ((candidate - act).to_i % interval).zero?

          candidate += 1.day
        end

        raise ArgumentError, "no next every_x_days occurrence in search window"
      when "monthly"
        raise ArgumentError if user_habit.activation_date.blank?

        anchor_day = user_habit.activation_date.day
        next_month = date.next_month
        last_day = Date.new(next_month.year, next_month.month, -1).day
        day = [ anchor_day, last_day ].min
        Date.new(next_month.year, next_month.month, day)
      else
        raise NotImplementedError, "next_occurrence_after not implemented for #{user_habit.frequency_type.inspect}"
      end
    end

    def self.normalized_weekdays(user_habit)
      raw = user_habit.frequency_params.is_a?(Hash) ? user_habit.frequency_params["weekdays"] : nil
      return [] unless raw.is_a?(Array)

      raw.select { |v| v.is_a?(Integer) && v.between?(0, 6) }
    end
    private_class_method :normalized_weekdays
  end
end
