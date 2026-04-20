# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::RecomputeStreakCountersJob, type: :job do
  include ActiveJob::TestHelper

  # [REQ-RPT-002]
  it "invokes the recompute service for an existing habit" do
    habit = create(:user_habit)
    allow(Habits::RecomputeStreakCounters).to receive(:call)

    described_class.perform_now(user_habit_id: habit.id)

    expect(Habits::RecomputeStreakCounters).to have_received(:call).with(user_habit: habit)
  end

  # [REQ-RPT-002]
  it "no-ops when the habit no longer exists" do
    allow(Habits::RecomputeStreakCounters).to receive(:call)

    expect {
      described_class.perform_now(user_habit_id: -1)
    }.not_to raise_error

    expect(Habits::RecomputeStreakCounters).not_to have_received(:call)
  end
end

