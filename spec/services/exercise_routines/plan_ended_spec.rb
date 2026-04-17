# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExerciseRoutines::PlanEnded do
  let(:user) { create(:user, password: "Password123!") }

  def routine!(name: "R")
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "x")
    r.tap(&:save!)
  end

  let(:routine) { routine! }

  # [REQ-EXR-005]
  it "is false when week_index is blank" do
    expect(described_class.call(user: user, week_index: nil)).to eq(false)
  end

  # [REQ-EXR-005]
  it "is false when there are no routine assignments" do
    expect(described_class.call(user: user, week_index: 5)).to eq(false)
  end

  # [REQ-EXR-005]
  it "is false when the week is still inside the last range" do
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine, start_week: 1, end_week: 4)
    expect(described_class.call(user: user, week_index: 4)).to eq(false)
  end

  # [REQ-EXR-005]
  it "is true when the current week is past the maximum assigned end_week" do
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine, start_week: 1, end_week: 4)
    expect(described_class.call(user: user, week_index: 5)).to eq(true)
  end

  # [REQ-EXR-005]
  it "does not use menu phase_assignments for the predicate" do
    menu = Menu.create!(user: user, name: "M")
    PhaseAssignment.create!(user: user, menu: menu, start_week: 1, end_week: 10)
    expect(described_class.call(user: user, week_index: 20)).to eq(false)
  end
end
