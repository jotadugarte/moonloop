# frozen_string_literal: true

module Phases
  # REQ-MENU-003: week_index = floor((local_date - phase1_start) / 7) + 1 when local_date >= anchor.
  # +local_date+ must already be the user's civil calendar date (caller uses their IANA timezone).
  class WeekNumber
    def self.for_local_date(user:, local_date:)
      new(user: user, local_date: local_date).value
    end

    def self.today_for(user)
      tz = user.timezone.presence || "Etc/UTC"
      local_date = Time.current.in_time_zone(tz).to_date
      for_local_date(user: user, local_date: local_date)
    end

    def initialize(user:, local_date:)
      @user = user
      @local_date = local_date
    end

    def value
      anchor = @user.phase_one_starts_on
      return nil if anchor.blank?
      return nil if @local_date < anchor

      days = (@local_date - anchor).to_i
      (days / 7) + 1
    end
  end
end
