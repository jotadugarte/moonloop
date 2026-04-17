# frozen_string_literal: true

require "rails_helper"

RSpec.describe Phases::ProcessPhaseStartReminderForUser do
  let(:anchor) { Date.new(2026, 6, 2) }
  let(:user) do
    create(
      :user,
      timezone: "Europe/Madrid",
      phase_one_starts_on: anchor,
      phase_reminder_email: true,
      phase_reminder_in_app: true
    )
  end

  before { ActionMailer::Base.deliveries.clear }

  # [REQ-MENU-004]
  it "creates one event and sends one email when today is the phase anchor in the user timezone" do
    madrid = ActiveSupport::TimeZone["Europe/Madrid"].local(2026, 6, 2, 9, 0, 0)
    travel_to(madrid) do
      expect {
        described_class.call(user: user.reload)
      }.to change(PhaseReminderEvent, :count).by(1)
        .and change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end

  # [REQ-MENU-004]
  it "is idempotent when the job runs twice the same local day" do
    madrid = ActiveSupport::TimeZone["Europe/Madrid"].local(2026, 6, 2, 9, 0, 0)
    travel_to(madrid) do
      2.times { described_class.call(user: user.reload) }
      expect(PhaseReminderEvent.count).to eq(1)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end
  end

  # [REQ-MENU-004]
  it "does nothing when the local calendar day is before the anchor" do
    madrid = ActiveSupport::TimeZone["Europe/Madrid"].local(2026, 6, 1, 9, 0, 0)
    travel_to(madrid) do
      expect {
        described_class.call(user: user.reload)
      }.not_to change(PhaseReminderEvent, :count)
    end
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  # [REQ-MENU-004]
  it "does nothing when both reminder channels are disabled" do
    user.update!(phase_reminder_email: false, phase_reminder_in_app: false)
    madrid = ActiveSupport::TimeZone["Europe/Madrid"].local(2026, 6, 2, 9, 0, 0)
    travel_to(madrid) do
      expect {
        described_class.call(user: user.reload)
      }.not_to change(PhaseReminderEvent, :count)
    end
  end

  # [REQ-MENU-004]
  it "records an event but skips email when only in-app is enabled" do
    user.update!(phase_reminder_email: false, phase_reminder_in_app: true)
    madrid = ActiveSupport::TimeZone["Europe/Madrid"].local(2026, 6, 2, 9, 0, 0)
    travel_to(madrid) do
      expect {
        described_class.call(user: user.reload)
      }.to change(PhaseReminderEvent, :count).by(1)
    end
    expect(ActionMailer::Base.deliveries).to be_empty
  end
end
