# frozen_string_literal: true

module Phases
  # REQ-MENU-005: current program week is past every assigned week range.
  class PlanEnded
    def self.call(user:, week_index:)
      new(user: user, week_index: week_index).call
    end

    def initialize(user:, week_index:)
      @user = user
      @week_index = week_index
    end

    def call
      return false if @week_index.blank?

      max_end = @user.phase_assignments.maximum(:end_week)
      return false if max_end.nil?

      @week_index > max_end
    end
  end
end
