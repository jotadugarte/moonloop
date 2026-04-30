# frozen_string_literal: true

require "rails_helper"

RSpec.describe Programs::ApplyBundleToUser do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def routine_for(u, name)
    r = ExerciseRoutine.new(user: u, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Línea")
    r.save!
    r
  end

  # [REQ-PHS-001]
  it "requires an explicit anchor date selection when applying" do
    user.update!(phase_one_starts_on: nil)
    program = PhaseProgram.create!(user: user, name: "Bundle")

    expect do
      described_class.call(phase_program: program, user: user)
    end.to raise_error(described_class::Error)
  end

  # [REQ-PHS-001]
  it "sets the user's anchor date to the selected value while applying" do
    user.update!(phase_one_starts_on: nil)
    menu = Menu.create!(user: user, name: "Menú")
    routine = routine_for(user, "Rutina")
    program = PhaseProgram.create!(user: user, name: "Bundle")
    PhaseProgramAssignment.create!(
      phase_program: program,
      menu: menu,
      exercise_routine: routine,
      start_week: 1,
      end_week: 2
    )

    described_class.call(phase_program: program, user: user, phase_one_starts_on: Date.new(2026, 1, 15))

    expect(user.reload.phase_one_starts_on).to eq(Date.new(2026, 1, 15))
    expect(user.phase_assignments.count).to eq(1)
    expect(user.exercise_routine_assignments.count).to eq(1)
  end
end
