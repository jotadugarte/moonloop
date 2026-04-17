# frozen_string_literal: true

require "rails_helper"

RSpec.describe Phases::PhaseStartInAppReminderVisible do
  let(:anchor) { Date.new(2026, 8, 15) }
  let(:user) do
    create(
      :user,
      timezone: "Europe/Berlin",
      phase_one_starts_on: anchor,
      phase_reminder_in_app: true,
      phase_reminder_dismissed_on: nil
    )
  end

  # [REQ-MENU-004]
  it "is true on the anchor local day when in-app is enabled and not dismissed" do
    berlin = ActiveSupport::TimeZone["Europe/Berlin"].local(2026, 8, 15, 9, 0, 0)
    travel_to(berlin) do
      expect(described_class.call(user: user.reload)).to eq(true)
    end
  end

  # [REQ-MENU-004]
  it "is false when the user dismissed for the current local day" do
    user.update!(phase_reminder_dismissed_on: anchor)
    berlin = ActiveSupport::TimeZone["Europe/Berlin"].local(2026, 8, 15, 9, 0, 0)
    travel_to(berlin) do
      expect(described_class.call(user: user.reload)).to eq(false)
    end
  end

  # [REQ-MENU-004]
  it "is false when in-app reminders are disabled" do
    user.update!(phase_reminder_in_app: false)
    berlin = ActiveSupport::TimeZone["Europe/Berlin"].local(2026, 8, 15, 9, 0, 0)
    travel_to(berlin) do
      expect(described_class.call(user: user.reload)).to eq(false)
    end
  end

  # [REQ-EXR-004]
  it "is true on the anchor day when the user only has exercise routine assignments" do
    er = ExerciseRoutine.new(user: user, name: "Solo rutina")
    er.exercise_routine_lines.build(weekday: 0, position: 0, label: "x")
    er.save!
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: er, start_week: 1, end_week: 4)

    berlin = ActiveSupport::TimeZone["Europe/Berlin"].local(2026, 8, 15, 9, 0, 0)
    travel_to(berlin) do
      expect(described_class.call(user: user.reload)).to eq(true)
    end
  end
end
