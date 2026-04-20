# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phase programs (bundles)", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  def routine_for(u, name)
    r = ExerciseRoutine.new(user: u, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Line")
    r.save!
    r
  end

  # [REQ-PHS-001]
  it "lists programs and creates one" do
    get phase_programs_path
    expect(response).to have_http_status(:ok)

    post phase_programs_path, params: { phase_program: { name: "  Verano  ", publicly_shareable: "0" } }

    expect(response).to have_http_status(:found)
    program = PhaseProgram.find_by!(user: user, name: "Verano")
    expect(response).to redirect_to(edit_phase_program_path(program))
  end

  # [REQ-PHS-001]
  it "adds two segments and applies them to the global phase plan" do
    menu_a = Menu.create!(user: user, name: "Menu A")
    menu_b = Menu.create!(user: user, name: "Menu B")
    routine_a = routine_for(user, "Routine A")
    routine_b = routine_for(user, "Routine B")
    program = PhaseProgram.create!(user: user, name: "Bundle")

    post phase_program_phase_program_assignments_path(program),
      params: {
        phase_program_assignment: {
          menu_id: menu_a.id,
          exercise_routine_id: routine_a.id,
          start_week: 1,
          end_week: 4
        }
      }
    expect(response).to have_http_status(:found)

    post phase_program_phase_program_assignments_path(program),
      params: {
        phase_program_assignment: {
          menu_id: menu_b.id,
          exercise_routine_id: routine_b.id,
          start_week: 5,
          end_week: 8
        }
      }
    expect(response).to have_http_status(:found)

    PhaseAssignment.create!(user: user, menu: menu_a, start_week: 99, end_week: 100)
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine_a, start_week: 99, end_week: 100)

    post apply_phase_program_path(program)

    expect(response).to have_http_status(:found)
    user.reload
    expect(user.phase_assignments.order(:start_week).pluck(:menu_id, :start_week, :end_week)).to eq(
      [ [ menu_a.id, 1, 4 ], [ menu_b.id, 5, 8 ] ]
    )
    expect(user.exercise_routine_assignments.order(:start_week).pluck(:exercise_routine_id, :start_week, :end_week)).to eq(
      [ [ routine_a.id, 1, 4 ], [ routine_b.id, 5, 8 ] ]
    )
  end

  # [REQ-CAT-001]
  it "lets the owner save optional catalog listing facet fields from edit" do
    program = PhaseProgram.create!(user: user, name: "Prog facet", publicly_shareable: true)

    patch phase_program_path(program),
      params: {
        phase_program: {
          name: "Prog facet",
          publicly_shareable: "1",
          catalog_listing_facet_attributes: {
            goal_phrase: "recomposición",
            difficulty_level: "advanced",
            normalized_tags: "cutting",
            duration_weeks_min: "1",
            duration_weeks_max: "8"
          }
        }
      }

    expect(response).to redirect_to(edit_phase_program_path(program))
    facet = program.reload.catalog_listing_facet
    expect(facet).to be_present
    expect(facet.goal_phrase).to eq("recomposición")
    expect(facet.difficulty_level).to eq("advanced")
  end

  # [REQ-PHS-001]
  it "returns not found when editing another user's program" do
    other = create(:user, password: "Password123!")
    foreign = PhaseProgram.create!(user: other, name: "Theirs")

    get edit_phase_program_path(foreign)

    expect(response).to have_http_status(:not_found)
  end
end
