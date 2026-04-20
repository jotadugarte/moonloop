# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalog::MaterializePhaseProgramFacetDuration do
  let(:user) { create(:user) }
  let(:menu) { Menu.create!(user: user, name: "M") }

  def routine(name)
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "L")
    r.save!
    r
  end

  # [REQ-CAT-001]
  it "sets facet duration from minimum start_week and maximum end_week" do
    program = PhaseProgram.create!(user: user, name: "P")
    facet = Catalog::ListingFacet.create!(listable: program, goal_phrase: "x")
    rt = routine("R")
    PhaseProgramAssignment.create!(phase_program: program, menu: menu, exercise_routine: rt, start_week: 2, end_week: 5)
    PhaseProgramAssignment.create!(phase_program: program, menu: menu, exercise_routine: rt, start_week: 6, end_week: 11)

    described_class.call(program)

    facet.reload
    expect(facet.duration_weeks_min).to eq(2)
    expect(facet.duration_weeks_max).to eq(11)
  end

  # [REQ-CAT-001]
  it "clears facet duration when there are no assignments" do
    program = PhaseProgram.create!(user: user, name: "Empty")
    facet = Catalog::ListingFacet.create!(
      listable: program,
      goal_phrase: "x",
      duration_weeks_min: 1,
      duration_weeks_max: 4
    )

    described_class.call(program)

    facet.reload
    expect(facet.duration_weeks_min).to be_nil
    expect(facet.duration_weeks_max).to be_nil
  end

  # [REQ-CAT-001]
  it "no-ops when the program has no catalog listing facet" do
    program = PhaseProgram.create!(user: user, name: "No facet")

    expect { described_class.call(program) }.not_to change(Catalog::ListingFacet, :count)
  end

  # [REQ-CAT-001]
  it "runs after a phase program assignment is committed" do
    program = PhaseProgram.create!(user: user, name: "Auto")
    facet = Catalog::ListingFacet.create!(listable: program, goal_phrase: "y")
    rt = routine("R2")
    PhaseProgramAssignment.create!(phase_program: program, menu: menu, exercise_routine: rt, start_week: 3, end_week: 8)

    facet.reload
    expect(facet.duration_weeks_min).to eq(3)
    expect(facet.duration_weeks_max).to eq(8)
  end
end
