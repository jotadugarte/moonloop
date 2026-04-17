# frozen_string_literal: true

module Phases
  class PhaseStartInAppReminderVisible
    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      return false unless @user.phase_reminder_in_app?
      return false if @user.phase_one_starts_on.blank?

      tz = Time.find_zone(@user.timezone)
      return false if tz.blank?

      local_today = tz.today
      return false unless @user.phase_one_starts_on == local_today
      return false if @user.phase_reminder_dismissed_on == local_today

      true
    end
  end
end
