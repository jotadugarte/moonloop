# frozen_string_literal: true

module Habits
  # REQ-RPT-002: Current streak for Informes must match Mi Día — same +as_of+, optional
  # +completions_by_date+ (by +completed_on+), and +Habits::Streak+ rules (REQ-DAY-004).
  class ReportCurrentStreak
    def self.call(user_habit:, as_of:, completions_by_date: nil)
      Streak.call(
        user_habit: user_habit,
        as_of: as_of,
        completions_by_date: completions_by_date
      )
    end
  end
end
