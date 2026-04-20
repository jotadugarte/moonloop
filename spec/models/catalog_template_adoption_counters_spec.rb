# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Catalog template adoption counters (REQ-CAT-001)", :aggregate_failures do
  let(:user) { create(:user) }

  # [REQ-CAT-001]
  it "persists Menu counters defaulting to zero" do
    menu = Menu.create!(user: user, name: "Plan A")
    expect(menu.public_catalog_adoptions_count).to eq(0)
    expect(menu.public_catalog_distinct_adopters_count).to eq(0)
  end

  # [REQ-CAT-001]
  it "persists ExerciseRoutine counters defaulting to zero" do
    routine = ExerciseRoutine.new(user: user, name: "Rutina A")
    routine.exercise_routine_lines.build(weekday: 0, position: 0, label: "Warmup")
    routine.save!
    expect(routine.public_catalog_adoptions_count).to eq(0)
    expect(routine.public_catalog_distinct_adopters_count).to eq(0)
  end

  # [REQ-CAT-001]
  it "persists PhaseProgram counters defaulting to zero" do
    program = PhaseProgram.create!(user: user, name: "Bundle A")
    expect(program.public_catalog_adoptions_count).to eq(0)
    expect(program.public_catalog_distinct_adopters_count).to eq(0)
  end
end
