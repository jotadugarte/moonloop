# frozen_string_literal: true

require "rails_helper"

RSpec.describe Programs::ApplyBundleToUser do
  let(:user) { create(:user, password: "Password123!") }
  let(:other) { create(:user, password: "Password123!") }

  def routine_for(u, name)
    r = ExerciseRoutine.new(user: u, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Línea")
    r.save!
    r
  end

  # [REQ-PHS-001]
  it "raises wrong_owner when the program does not belong to the user" do
    program = PhaseProgram.create!(user: other, name: "Ajeno")
    expect do
      described_class.call(phase_program: program, user: user)
    end.to raise_error(described_class::Error) do |err|
      expect(err.key).to eq(:wrong_owner)
    end
  end

  # [REQ-PHS-001]
  it "replaces phase_assignments and exercise_routine_assignments from program segments" do
    menu_a = Menu.create!(user: user, name: "Menú A")
    menu_b = Menu.create!(user: user, name: "Menú B")
    routine_a = routine_for(user, "Rutina A")
    routine_b = routine_for(user, "Rutina B")
    program = PhaseProgram.create!(user: user, name: "Bundle")
    PhaseProgramAssignment.create!(
      phase_program: program,
      menu: menu_a,
      exercise_routine: routine_a,
      start_week: 1,
      end_week: 4
    )
    PhaseProgramAssignment.create!(
      phase_program: program,
      menu: menu_b,
      exercise_routine: routine_b,
      start_week: 5,
      end_week: 8
    )

    described_class.call(phase_program: program, user: user)

    user.reload
    expect(user.phase_assignments.order(:start_week).pluck(:menu_id, :start_week, :end_week)).to eq(
      [ [ menu_a.id, 1, 4 ], [ menu_b.id, 5, 8 ] ]
    )
    expect(user.exercise_routine_assignments.order(:start_week).pluck(:exercise_routine_id, :start_week, :end_week)).to eq(
      [ [ routine_a.id, 1, 4 ], [ routine_b.id, 5, 8 ] ]
    )
  end

  # [REQ-PHS-001]
  it "clears prior assignments when applying (replace semantics)" do
    menu_a = Menu.create!(user: user, name: "Menú A")
    menu_b = Menu.create!(user: user, name: "Menú B")
    routine_a = routine_for(user, "Rutina A")
    routine_b = routine_for(user, "Rutina B")
    PhaseAssignment.create!(user: user, menu: menu_a, start_week: 10, end_week: 12)
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine_a, start_week: 10, end_week: 12)

    program = PhaseProgram.create!(user: user, name: "Bundle")
    PhaseProgramAssignment.create!(
      phase_program: program,
      menu: menu_b,
      exercise_routine: routine_b,
      start_week: 1,
      end_week: 2
    )

    described_class.call(phase_program: program, user: user)

    user.reload
    expect(user.phase_assignments.count).to eq(1)
    expect(user.phase_assignments.first).to have_attributes(menu_id: menu_b.id, start_week: 1, end_week: 2)
    expect(user.exercise_routine_assignments.count).to eq(1)
    expect(user.exercise_routine_assignments.first).to have_attributes(
      exercise_routine_id: routine_b.id,
      start_week: 1,
      end_week: 2
    )
  end

  # [REQ-PHS-001]
  it "clears both assignment tables when the program has no segments" do
    menu = Menu.create!(user: user, name: "Solo")
    routine = routine_for(user, "Solo")
    PhaseAssignment.create!(user: user, menu: menu, start_week: 1, end_week: 2)
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine, start_week: 1, end_week: 2)
    program = PhaseProgram.create!(user: user, name: "Vacío")

    described_class.call(phase_program: program, user: user)

    user.reload
    expect(user.phase_assignments).to be_empty
    expect(user.exercise_routine_assignments).to be_empty
  end
end
