# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExerciseRoutines::AppendLineForWeekday do
  let(:user) { create(:user) }
  let(:routine) do
    r = ExerciseRoutine.new(user: user, name: "R")
    r.exercise_routine_lines.build(weekday: 1, position: 0, label: "A")
    r.tap(&:save!)
  end

  # [REQ-EXR-001]
  it "appends the next position for the weekday" do
    described_class.call(routine: routine, weekday: 1)
    described_class.call(routine: routine, weekday: 1)

    lines = routine.exercise_routine_lines.select { |l| l.weekday == 1 }
    expect(lines.map(&:position).sort).to eq([ 0, 1, 2 ])
  end
end
