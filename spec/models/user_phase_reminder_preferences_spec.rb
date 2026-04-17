# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, "phase reminder preferences" do
  # [REQ-MENU-004]
  it "defaults in-app and email reminder channels to enabled" do
    user = create(:user)
    expect(user.phase_reminder_in_app).to eq(true)
    expect(user.phase_reminder_email).to eq(true)
  end

  # [REQ-MENU-004]
  it "allows disabling in-app reminders while keeping email enabled" do
    user = create(:user)
    user.update!(phase_reminder_in_app: false, phase_reminder_email: true)
    user.reload
    expect(user.phase_reminder_in_app).to eq(false)
    expect(user.phase_reminder_email).to eq(true)
  end
end
