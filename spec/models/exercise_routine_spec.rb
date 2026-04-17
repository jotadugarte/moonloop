# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExerciseRoutine, type: :model do
  let(:user) { create(:user) }

  # [REQ-EXR-001]
  it "belongs to a user" do
    routine = described_class.new(name: "Rutina A", user: user)
    expect(routine.user).to eq(user)
  end

  # [REQ-EXR-001]
  it "has many exercise_routine_lines" do
    expect(described_class.reflect_on_association(:exercise_routine_lines).macro).to eq(:has_many)
  end

  # [REQ-EXR-001]
  it "requires name" do
    routine = described_class.new(user: user, name: "   ")
    expect(routine).not_to be_valid
    expect(routine.errors[:name]).to be_present
  end

  # [REQ-EXR-001]
  it "normalizes name by stripping whitespace" do
    routine = described_class.new(user: user, name: "  Verano  ")
    routine.valid?
    expect(routine.name).to eq("Verano")
  end

  # [REQ-EXR-001]
  it "rejects a second routine with the same normalized name for the same user" do
    first = described_class.new(user: user, name: "Fuerza")
    first.exercise_routine_lines.build(weekday: 0, position: 0, label: "Tirón")
    first.save!

    dup = described_class.new(user: user, name: "  fuerza  ")
    dup.exercise_routine_lines.build(weekday: 1, position: 0, label: "Empuje")
    expect(dup).not_to be_valid
    expect(dup.errors[:name]).to be_present
  end

  # [REQ-EXR-001]
  it "allows the same display name for a different user" do
    other = create(:user)
    first = described_class.new(user: user, name: "Común")
    first.exercise_routine_lines.build(weekday: 1, position: 0, label: "A")
    first.save!

    second = described_class.new(user: other, name: "Común")
    second.exercise_routine_lines.build(weekday: 2, position: 0, label: "B")
    expect(second).to be_valid
  end

  # [REQ-EXR-001]
  it "is invalid when it has no lines on any weekday (globally empty)" do
    routine = described_class.new(user: user, name: "Vacía")
    expect(routine).not_to be_valid
    expect(routine.errors[:base]).to be_present
  end

  # [REQ-EXR-001]
  it "is valid with at least one line on one weekday" do
    routine = described_class.new(user: user, name: "Completa")
    routine.exercise_routine_lines.build(weekday: 3, position: 0, label: "Caminar")
    expect(routine).to be_valid
  end
end
