# frozen_string_literal: true

module Phases
  class SweepPhaseStartRemindersJob < ApplicationJob
    queue_as :default

    def perform
      User.where.not(phase_one_starts_on: nil).find_each do |user|
        Phases::ProcessPhaseStartReminderForUser.call(user: user)
      end
    end
  end
end
