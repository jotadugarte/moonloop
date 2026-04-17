# frozen_string_literal: true

require "rails_helper"

RSpec.describe Phases::SweepPhaseStartRemindersJob, type: :job do
  # [REQ-MENU-004]
  it "invokes the per-user processor for users with a phase anchor only" do
    with_anchor = create(:user, phase_one_starts_on: Date.new(2026, 1, 5))
    without_anchor = create(:user, phase_one_starts_on: nil)

    allow(Phases::ProcessPhaseStartReminderForUser).to receive(:call)

    described_class.perform_now

    expect(Phases::ProcessPhaseStartReminderForUser).to have_received(:call).with(user: with_anchor)
    expect(Phases::ProcessPhaseStartReminderForUser).not_to have_received(:call).with(user: without_anchor)
  end
end
