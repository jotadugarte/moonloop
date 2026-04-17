# frozen_string_literal: true

module Phases
  class ResolveActiveMenu
    def self.call(user:, week_index:)
      new(user: user, week_index: week_index).menu
    end

    def initialize(user:, week_index:)
      @user = user
      @week_index = week_index
    end

    def menu
      return nil if @week_index.blank?

      assignment = @user.phase_assignments
        .includes(:menu)
        .order(:start_week)
        .find_by("? BETWEEN start_week AND end_week", @week_index)

      assignment&.menu
    end
  end
end
