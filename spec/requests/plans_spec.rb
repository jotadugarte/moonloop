# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Plans (bundles)", type: :request do
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
  it "lists plans and creates one" do
    get plans_path
    expect(response).to have_http_status(:ok)

    post plans_path, params: { plan: { name: "  Verano  ", publicly_shareable: "0" } }

    expect(response).to have_http_status(:found)
    plan = Plan.find_by!(user: user, name: "Verano")
    expect(response).to redirect_to(edit_plan_path(plan))
  end

  # [REQ-PHS-001]
  it "adds two segments and applies them to the global phase plan" do
    menu_a = Menu.create!(user: user, name: "Menu A")
    menu_b = Menu.create!(user: user, name: "Menu B")
    routine_a = routine_for(user, "Routine A")
    routine_b = routine_for(user, "Routine B")
    plan = Plan.create!(user: user, name: "Bundle")

    post plan_plan_assignments_path(plan),
      params: {
        plan_assignment: {
          menu_id: menu_a.id,
          exercise_routine_id: routine_a.id,
          start_week: 1,
          end_week: 4
        }
      }
    expect(response).to have_http_status(:found)

    post plan_plan_assignments_path(plan),
      params: {
        plan_assignment: {
          menu_id: menu_b.id,
          exercise_routine_id: routine_b.id,
          start_week: 5,
          end_week: 8
        }
      }
    expect(response).to have_http_status(:found)

    PhaseAssignment.create!(user: user, menu: menu_a, start_week: 99, end_week: 100)
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine_a, start_week: 99, end_week: 100)

    post apply_plan_path(plan), params: { phase_one_starts_on: Date.new(2026, 1, 15) }

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
    plan = Plan.create!(user: user, name: "Prog facet", publicly_shareable: true)

    patch plan_path(plan),
      params: {
        plan: {
          name: "Prog facet",
          publicly_shareable: "1",
          catalog_listing_facet_attributes: {
            goal_phrase: "recomposición",
            difficulty_level: "advanced",
            normalized_tags: "cutting"
          }
        }
      }

    expect(response).to redirect_to(edit_plan_path(plan))
    facet = plan.reload.catalog_listing_facet
    expect(facet).to be_present
    expect(facet.goal_phrase).to eq("recomposición")
    expect(facet.difficulty_level).to eq("advanced")
  end

  # [REQ-CAT-001]
  it "materializes catalog facet duration from plan segments (not the facet form)" do
    menu_a = Menu.create!(user: user, name: "Ma")
    routine_a = routine_for(user, "Ra")
    plan = Plan.create!(user: user, name: "Seg dura", publicly_shareable: true)
    Catalog::ListingFacet.create!(listable: plan, goal_phrase: "plan")

    post plan_plan_assignments_path(plan),
      params: {
        plan_assignment: {
          menu_id: menu_a.id,
          exercise_routine_id: routine_a.id,
          start_week: 1,
          end_week: 4
        }
      }
    expect(response).to have_http_status(:found)

    post plan_plan_assignments_path(plan),
      params: {
        plan_assignment: {
          menu_id: menu_a.id,
          exercise_routine_id: routine_a.id,
          start_week: 5,
          end_week: 12
        }
      }
    expect(response).to have_http_status(:found)

    facet = plan.reload.catalog_listing_facet
    expect(facet.duration_weeks_min).to eq(1)
    expect(facet.duration_weeks_max).to eq(12)
  end

  # [REQ-PHS-001]
  it "returns not found when editing another user's plan" do
    other = create(:user, password: "Password123!")
    foreign = Plan.create!(user: other, name: "Theirs")

    get edit_plan_path(foreign)

    expect(response).to have_http_status(:not_found)
  end
end
