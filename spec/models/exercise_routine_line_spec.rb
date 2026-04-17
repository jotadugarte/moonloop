# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExerciseRoutineLine, type: :model do
  let(:user) { create(:user) }
  let(:routine) do
    r = ExerciseRoutine.new(user: user, name: "Base")
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Calentar")
    r.tap(&:save!)
  end

  # [REQ-EXR-001]
  it "belongs to exercise_routine" do
    line = described_class.new(
      exercise_routine: routine,
      weekday: 1,
      position: 0,
      label: "Sentadillas"
    )
    expect(line.exercise_routine).to eq(routine)
  end

  # [REQ-EXR-001]
  it "requires weekday between 0 and 6" do
    bad = described_class.new(exercise_routine: routine, weekday: 7, position: 0, label: "X")
    expect(bad).not_to be_valid
    expect(bad.errors[:weekday]).to be_present
  end

  # [REQ-EXR-001]
  it "requires unique position per weekday within a routine" do
    described_class.create!(exercise_routine: routine, weekday: 3, position: 0, label: "A")
    dup = described_class.new(exercise_routine: routine, weekday: 3, position: 0, label: "B")
    expect(dup).not_to be_valid
    expect(dup.errors[:position]).to be_present
  end

  # [REQ-EXR-001]
  it "allows the same position on a different weekday" do
    described_class.create!(exercise_routine: routine, weekday: 1, position: 0, label: "A")
    other = described_class.new(exercise_routine: routine, weekday: 2, position: 0, label: "B")
    expect(other).to be_valid
  end

  # [REQ-EXR-001]
  it "requires a primary label" do
    line = described_class.new(exercise_routine: routine, weekday: 4, position: 0, label: "   ")
    expect(line).not_to be_valid
    expect(line.errors[:label]).to be_present
  end

  # [REQ-EXR-001]
  it "rejects label text beyond the migration limit" do
    long = "x" * 600
    line = described_class.new(exercise_routine: routine, weekday: 5, position: 0, label: long)
    expect(line).not_to be_valid
    expect(line.errors[:label]).to be_present
  end
end
