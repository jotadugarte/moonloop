# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phase block coverage", type: :model do
  let(:user) { create(:user, password: "Password123!") }
  let(:menu_a) { Menu.create!(user: user, name: "Menú A") }
  let(:menu_b) { Menu.create!(user: user, name: "Menú B") }

  def routine_for(u, name)
    r = ExerciseRoutine.new(user: u, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Línea")
    r.save!
    r
  end

  let(:routine_a) { routine_for(user, "Rutina A") }
  let(:routine_b) { routine_for(user, "Rutina B") }

  # [REQ-PHS-001] — phases blocks (REQ-ID finalized in SPEC step S11 of task plan)
  it "rejects gaps in menu blocks (must cover all weeks_total)" do
    phase = Phase.create!(user: user, name: "Fase", weeks_total: 4)
    PhaseMenuBlock.create!(phase: phase, menu: menu_a, start_week: 1, end_week: 2)
    PhaseMenuBlock.create!(phase: phase, menu: menu_b, start_week: 4, end_week: 4)
    PhaseRoutineBlock.create!(phase: phase, exercise_routine: routine_a, start_week: 1, end_week: 4)

    expect(phase).not_to be_valid
    expect(phase.errors.added?(:base, :menu_blocks_incomplete_coverage)).to eq(true)
  end

  # [REQ-PHS-001] — phases blocks (REQ-ID finalized in SPEC step S11 of task plan)
  it "rejects overlaps in routine blocks" do
    phase = Phase.create!(user: user, name: "Fase", weeks_total: 4)
    PhaseMenuBlock.create!(phase: phase, menu: menu_a, start_week: 1, end_week: 4)
    PhaseRoutineBlock.create!(phase: phase, exercise_routine: routine_a, start_week: 1, end_week: 3)
    PhaseRoutineBlock.create!(phase: phase, exercise_routine: routine_b, start_week: 3, end_week: 4)

    expect(phase).not_to be_valid
    expect(phase.errors.added?(:base, :routine_blocks_overlap)).to eq(true)
  end

  # [REQ-PHS-001] — phases blocks (REQ-ID finalized in SPEC step S11 of task plan)
  it "rejects when a week has menu coverage but no routine coverage (parity required)" do
    phase = Phase.create!(user: user, name: "Fase", weeks_total: 4)
    PhaseMenuBlock.create!(phase: phase, menu: menu_a, start_week: 1, end_week: 4)
    PhaseRoutineBlock.create!(phase: phase, exercise_routine: routine_a, start_week: 1, end_week: 3)

    expect(phase).not_to be_valid
    expect(phase.errors.added?(:base, :week_missing_routine)).to eq(true)
  end

  # [REQ-PHS-001] — phases blocks (REQ-ID finalized in SPEC step S11 of task plan)
  it "allows contiguous full coverage blocks for both menus and routines" do
    phase = Phase.create!(user: user, name: "Fase", weeks_total: 4)
    PhaseMenuBlock.create!(phase: phase, menu: menu_a, start_week: 1, end_week: 2)
    PhaseMenuBlock.create!(phase: phase, menu: menu_b, start_week: 3, end_week: 4)
    PhaseRoutineBlock.create!(phase: phase, exercise_routine: routine_a, start_week: 1, end_week: 2)
    PhaseRoutineBlock.create!(phase: phase, exercise_routine: routine_b, start_week: 3, end_week: 4)

    expect(phase).to be_valid
  end
end

