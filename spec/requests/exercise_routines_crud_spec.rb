# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Exercise routines CRUD", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  def create_routine!(name: "Base", label: "Squat")
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: label)
    r.tap(&:save!)
  end

  # [REQ-EXR-001]
  it "lists routines for the signed-in user" do
    create_routine!(name: "Fuerza")

    get exercise_routines_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Fuerza")
  end

  # [REQ-EXR-001]
  it "creates a routine with a first line" do
    post exercise_routines_path,
      params: {
        exercise_routine: {
          name: "Nueva rutina",
          exercise_routine_lines_attributes: {
            "0" => { weekday: 2, position: 0, label: "Press" }
          }
        }
      }

    expect(response).to have_http_status(:found)
    r = ExerciseRoutine.find_by!(user: user, name: "Nueva rutina")
    expect(r.exercise_routine_lines.count).to eq(1)
    expect(r.exercise_routine_lines.first.label).to eq("Press")
  end

  # [REQ-I18N-001]
  it "shows exercise routine validation errors in Spanish without translation-missing noise" do
    I18n.with_locale(:es) do
      post exercise_routines_path,
        params: {
          exercise_routine: {
            name: "",
            exercise_routine_lines_attributes: {
              "0" => { weekday: 0, position: 0, label: "" }
            }
          }
        }
    end

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).not_to include("Translation missing")
    expect(response.body).not_to include("Exercise routine lines")
  end

  # [REQ-EXR-006]
  it "creates a routine as publicly shareable when the owner opts in" do
    post exercise_routines_path,
      params: {
        exercise_routine: {
          name: "Rutina pública",
          publicly_shareable: "1",
          exercise_routine_lines_attributes: {
            "0" => { weekday: 0, position: 0, label: "Run" }
          }
        }
      }

    expect(response).to have_http_status(:found)
    r = ExerciseRoutine.find_by!(user: user, name: "Rutina pública")
    expect(r.publicly_shareable).to eq(true)
  end

  # [REQ-EXR-006]
  it "allows the owner to toggle publicly_shareable on update" do
    routine = create_routine!(name: "Toggle", label: "A")
    line = routine.exercise_routine_lines.sole

    patch exercise_routine_path(routine),
      params: {
        exercise_routine: {
          name: "Toggle",
          publicly_shareable: "1",
          exercise_routine_lines_attributes: {
            "0" => {
              id: line.id,
              weekday: line.weekday,
              position: line.position,
              label: line.label
            }
          }
        }
      }

    expect(response).to have_http_status(:found)
    expect(routine.reload.publicly_shareable).to eq(true)

    patch exercise_routine_path(routine),
      params: {
        exercise_routine: {
          name: "Toggle",
          publicly_shareable: "0",
          exercise_routine_lines_attributes: {
            "0" => {
              id: line.id,
              weekday: line.weekday,
              position: line.position,
              label: line.label
            }
          }
        }
      }

    expect(routine.reload.publicly_shareable).to eq(false)
  end

  # [REQ-CAT-001]
  it "lets the owner save optional catalog listing facet fields from edit" do
    routine = create_routine!(name: "Facet rutina", label: "Press")
    line = routine.exercise_routine_lines.sole

    patch exercise_routine_path(routine),
      params: {
        exercise_routine: {
          name: "Facet rutina",
          publicly_shareable: "1",
          exercise_routine_lines_attributes: {
            "0" => {
              id: line.id,
              weekday: line.weekday,
              position: line.position,
              label: line.label
            }
          },
          catalog_listing_facet_attributes: {
            goal_phrase: "resistencia",
            difficulty_level: "beginner",
            normalized_tags: "cardio",
            duration_weeks_min: "2",
            duration_weeks_max: "6"
          }
        }
      }

    expect(response).to redirect_to(edit_exercise_routine_path(routine))
    facet = routine.reload.catalog_listing_facet
    expect(facet).to be_present
    expect(facet.goal_phrase).to eq("resistencia")
    expect(facet.normalized_tags).to eq("cardio")
  end

  # [REQ-EXR-001]
  it "forbids editing another user's routine" do
    other = create(:user, password: "Password123!", timezone: "Etc/UTC")
    foreign = ExerciseRoutine.new(user: other, name: "Ajena")
    foreign.exercise_routine_lines.build(weekday: 0, position: 0, label: "x")
    foreign.save!

    get edit_exercise_routine_path(foreign)

    expect(response).to have_http_status(:not_found)
  end

  # [REQ-EXR-001]
  it "shows assignment count on confirm destroy" do
    routine = create_routine!
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine, start_week: 1, end_week: 2)
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine, start_week: 5, end_week: 6)

    get confirm_destroy_exercise_routine_path(routine)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("2")
  end

  # [REQ-EXR-001]
  it "destroys assignments then the routine in one request" do
    routine = create_routine!
    ExerciseRoutineAssignment.create!(user: user, exercise_routine: routine, start_week: 1, end_week: 4)

    before_assignments = ExerciseRoutineAssignment.count
    before_routines = ExerciseRoutine.count

    delete exercise_routine_path(routine)

    expect(response).to have_http_status(:found)
    expect(ExerciseRoutineAssignment.count).to eq(before_assignments - 1)
    expect(ExerciseRoutine.count).to eq(before_routines - 1)
  end

  # [REQ-EXR-001]
  it "duplicates a routine into a new editable routine" do
    routine = create_routine!(name: "Original", label: "A")

    expect do
      post duplicate_exercise_routine_path(routine)
    end.to change { ExerciseRoutine.count }.by(1)

    expect(response).to have_http_status(:found)
    copy = ExerciseRoutine.order(:created_at).last
    expect(copy.name).to include("Original")
    expect(copy.exercise_routine_lines.count).to eq(1)
    expect(copy.exercise_routine_lines.first.label).to eq("A")
  end

  # [REQ-EXR-001] — duplicate name collision uses I18n (collision_name)
  it "uniquifies duplicate names when the default copy label is already taken" do
    routine = create_routine!(name: "Original", label: "A")
    post duplicate_exercise_routine_path(routine)
    post duplicate_exercise_routine_path(routine)

    expect(response).to have_http_status(:found)
    second_copy = ExerciseRoutine.order(:created_at).last
    expected = I18n.t(
      "exercise_routines.duplicate.collision_name",
      base: I18n.t("exercise_routines.duplicate.default_name", name: "Original"),
      n: 2
    )
    expect(second_copy.name).to eq(expected)
  end
end
