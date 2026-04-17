# frozen_string_literal: true

FactoryBot.define do
  factory :phase_reminder_event do
    user
    kind { PhaseReminderEvent::KIND_PHASE_START }
    local_date { Date.current }
  end
end
