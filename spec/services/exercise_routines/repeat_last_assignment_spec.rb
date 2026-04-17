# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExerciseRoutines::RepeatLastAssignment do
  let(:user) { create(:user, password: "Password123!") }

  def routine!(name)
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "x")
    r.tap(&:save!)
  end

  let(:routine_a) { routine!("A") }
  let(:routine_b) { routine!("B") }

  # [REQ-EXR-005]
  it "returns nil when there are no routine assignments" do
    expect(described_class.call(user: user)).to be_nil
  end

  # [REQ-EXR-005]
  it "appends a range with the same routine and span as the block that ends last" do
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine_a, start_week: 1, end_week: 4)
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine_b, start_week: 5, end_week: 7)

    created = described_class.call(user: user.reload)

    expect(created).to be_persisted
    expect(created.exercise_routine).to eq(routine_b)
    expect(created.start_week).to eq(8)
    expect(created.end_week).to eq(10)
  end
end
