# frozen_string_literal: true

require "rails_helper"

RSpec.describe PhaseReminderEvent, type: :model do
  let(:user) { create(:user) }

  # [REQ-MENU-004]
  it "rejects duplicate user, kind, and local_date at the database" do
    create(:phase_reminder_event, user: user, kind: PhaseReminderEvent::KIND_PHASE_START, local_date: Date.new(2026, 8, 1))

    expect {
      PhaseReminderEvent.create!(
        user: user,
        kind: PhaseReminderEvent::KIND_PHASE_START,
        local_date: Date.new(2026, 8, 1)
      )
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
