# frozen_string_literal: true

module Phases
  class ProcessPhaseStartReminderForUser
    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      return if @user.phase_one_starts_on.blank?
      return unless @user.phase_reminder_email? || @user.phase_reminder_in_app?

      tz = Time.find_zone(@user.timezone)
      return if tz.blank?

      local_today = tz.today
      return unless @user.phase_one_starts_on == local_today

      begin
        PhaseReminderEvent.create!(
          user_id: @user.id,
          kind: PhaseReminderEvent::KIND_PHASE_START,
          local_date: local_today
        )
      rescue ActiveRecord::RecordNotUnique
        return
      end

      PhaseStartReminderMailer.notify(@user).deliver_now if @user.phase_reminder_email?
    end
  end
end
