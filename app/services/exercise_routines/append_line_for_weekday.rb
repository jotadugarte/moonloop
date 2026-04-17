# frozen_string_literal: true

module ExerciseRoutines
  # Builds the next line for a weekday when editing a routine (ordered positions per day).
  class AppendLineForWeekday
    def self.call(routine:, weekday:, label: nil)
      label ||= I18n.t("exercise_routines.edit.placeholder_line_label")
      new(routine: routine, weekday: weekday, label: label).call
    end

    def initialize(routine:, weekday:, label:)
      @routine = routine
      @weekday = weekday
      @label = label
    end

    def call
      w = @weekday.to_i.clamp(0, 6)
      max_p = lines_for_weekday(w).map(&:position).compact.max
      next_p = max_p.nil? ? 0 : max_p + 1
      @routine.exercise_routine_lines.build(weekday: w, position: next_p, label: @label)
    end

    private

    def lines_for_weekday(w)
      @routine.exercise_routine_lines
        .reject(&:marked_for_destruction?)
        .select { |l| l.weekday == w }
    end
  end
end
