# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plans::BuildFromPhases do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def routine_for(u, name)
    r = ExerciseRoutine.new(user: u, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Línea")
    r.save!
    r
  end

  # [REQ-PHS-001] — plans built from phases (REQ-ID finalized in SPEC step S11 of task plan)
  it "creates a Plan as a snapshot copy of selected phases, ordered sequentially with no gaps" do
    menu_a = Menu.create!(user: user, name: "Menú A")
    menu_b = Menu.create!(user: user, name: "Menú B")
    routine_a = routine_for(user, "Rutina A")
    routine_b = routine_for(user, "Rutina B")

    phase_1 = Phase.create!(user: user, name: "Fase 1", weeks_total: 2, publicly_shareable: false)
    PhaseMenuBlock.create!(phase: phase_1, menu: menu_a, start_week: 1, end_week: 2)
    PhaseRoutineBlock.create!(phase: phase_1, exercise_routine: routine_a, start_week: 1, end_week: 2)

    phase_2 = Phase.create!(user: user, name: "Fase 2", weeks_total: 2, publicly_shareable: false)
    PhaseMenuBlock.create!(phase: phase_2, menu: menu_b, start_week: 1, end_week: 2)
    PhaseRoutineBlock.create!(phase: phase_2, exercise_routine: routine_b, start_week: 1, end_week: 2)

    plan = described_class.call(user: user, name: "Plan X", phases: [phase_1, phase_2])

    expect(plan.user_id).to eq(user.id)
    expect(plan.name).to eq("Plan X")
    expect(plan.total_weeks).to eq(4)

    copied = plan.plan_phases.order(:position)
    expect(copied.map(&:position)).to eq([1, 2])
    expect(copied.map(&:weeks_total)).to eq([2, 2])
    expect(copied.map(&:source_phase_id)).to eq([phase_1.id, phase_2.id])

    expect(plan.menu_assignments.order(:start_week).pluck(:start_week, :end_week)).to eq([ [1, 2], [3, 4] ])
    expect(plan.routine_assignments.order(:start_week).pluck(:start_week, :end_week)).to eq([ [1, 2], [3, 4] ])
  end
end

