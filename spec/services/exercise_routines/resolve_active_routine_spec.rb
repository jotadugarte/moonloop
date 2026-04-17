# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExerciseRoutines::ResolveActiveRoutine do
  let(:user) { create(:user, password: "Password123!") }

  def routine_named(name)
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "x")
    r.tap(&:save!)
  end

  let(:routine_a) { routine_named("A") }
  let(:routine_b) { routine_named("B") }

  # [REQ-EXR-002]
  it "returns nil when week_index is nil" do
    expect(described_class.call(user: user, week_index: nil)).to be_nil
  end

  # [REQ-EXR-002]
  it "returns the exercise routine whose range covers the week index" do
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine_a, start_week: 1, end_week: 4)
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine_b, start_week: 5, end_week: 8)

    expect(described_class.call(user: user, week_index: 3)).to eq(routine_a)
    expect(described_class.call(user: user, week_index: 5)).to eq(routine_b)
  end

  # [REQ-EXR-002]
  it "returns nil when no assignment covers the week (gap)" do
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine_a, start_week: 1, end_week: 2)
    expect(described_class.call(user: user, week_index: 10)).to be_nil
  end
end
