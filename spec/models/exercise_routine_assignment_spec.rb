# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExerciseRoutineAssignment, type: :model do
  let(:user) { create(:user, password: "Password123!") }

  def routine_for(u, name: "Rutina base")
    r = ExerciseRoutine.new(user: u, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "x")
    r.tap(&:save!)
  end

  let(:routine) { routine_for(user) }

  # [REQ-EXR-002]
  it "rejects end_week before start_week" do
    a = described_class.new(user: user, exercise_routine: routine, start_week: 5, end_week: 3)
    expect(a).not_to be_valid
    expect(a.errors.added?(:end_week, :before_start_week)).to eq(true)
  end

  # [REQ-EXR-002]
  it "rejects overlapping week ranges for the same user (routine lane)" do
    described_class.create!(user: user, exercise_routine: routine, start_week: 1, end_week: 4)
    other_routine = routine_for(user, name: "Otra")
    dup = described_class.new(user: user, exercise_routine: other_routine, start_week: 3, end_week: 6)
    expect(dup).not_to be_valid
    expect(dup.errors.added?(:base, :range_overlap)).to eq(true)
  end

  # [REQ-EXR-002]
  it "allows adjacent ranges (no overlap)" do
    described_class.create!(user: user, exercise_routine: routine, start_week: 1, end_week: 4)
    other_routine = routine_for(user, name: "Otra")
    ok = described_class.create!(user: user, exercise_routine: other_routine, start_week: 5, end_week: 8)
    expect(ok).to be_persisted
  end

  # [REQ-EXR-002]
  it "rejects an exercise routine that belongs to another user" do
    other = create(:user, password: "Password123!")
    foreign_routine = routine_for(other, name: "Ajena")
    a = described_class.new(user: user, exercise_routine: foreign_routine, start_week: 1, end_week: 2)
    expect(a).not_to be_valid
    expect(a.errors.added?(:exercise_routine_id, :must_match_user)).to eq(true)
  end

  # [REQ-EXR-002] — DB-scoped overlap only; unsaved record must not overlap with itself
  it "is valid for a new assignment when no persisted ranges exist for the user" do
    a = described_class.new(user: user, exercise_routine: routine, start_week: 1, end_week: 4)
    expect(a).to be_valid
  end

  # [REQ-EXR-002]
  it "remains valid when updating in place without introducing overlap" do
    a = described_class.create!(user: user, exercise_routine: routine, start_week: 1, end_week: 4)
    a.assign_attributes(end_week: 5)
    expect(a).to be_valid
  end

  # [REQ-EXR-002] — independence from menu phase_assignments: same numeric range allowed for menu lane
  it "does not consider menu phase_assignments when checking routine overlap" do
    menu = Menu.create!(user: user, name: "Menú")
    PhaseAssignment.create!(user: user, menu: menu, start_week: 1, end_week: 4)
    other_routine = routine_for(user, name: "R2")
    ok = described_class.create!(user: user, exercise_routine: other_routine, start_week: 1, end_week: 4)
    expect(ok).to be_persisted
  end
end
