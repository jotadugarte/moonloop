module Habits
  class NextOccurrence
    def self.after(user_habit:, date:)
      raise ArgumentError unless date.is_a?(Date)

      case user_habit.frequency_type
      when "daily"
        date + 1.day
      when "monthly"
        raise ArgumentError if user_habit.activation_date.blank?

        anchor_day = user_habit.activation_date.day
        next_month = date.next_month
        last_day = Date.new(next_month.year, next_month.month, -1).day
        day = [anchor_day, last_day].min
        Date.new(next_month.year, next_month.month, day)
      else
        raise NotImplementedError, "next_occurrence_after not implemented for #{user_habit.frequency_type.inspect}"
      end
    end
  end
end
