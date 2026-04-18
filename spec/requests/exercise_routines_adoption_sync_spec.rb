# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Exercise routine adoption sync", type: :request do
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def sign_in!(user)
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  def create_public_routine(user:, name:, label: "A")
    r = ExerciseRoutine.new(user: user, name: name, publicly_shareable: true)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: label)
    r.save!
    r
  end

  def adopt!(adopter:, origin:, name: "Mi copia")
    sign_in!(adopter)
    post adopt_public_exercise_routine_path(origin), params: { name: name }
    ExerciseRoutine.find_by!(user: adopter, name: name)
  end

  # [REQ-EXR-006]
  it "shows pending adoption sync on edit when the source content changed" do
    origin = create_public_routine(user: author, name: "Origin", label: "Squat")
    copy = adopt!(adopter: adopter, origin: origin, name: "Mantener nombre")

    origin.exercise_routine_lines.first.update!(label: "Front squat")

    get edit_exercise_routine_path(copy)

    expect(response.body).to include(I18n.t("exercise_routines.edit.adoption_sync.pending"))
  end

  # [REQ-EXR-006]
  it "applies source lines and keeps copy name and assignments" do
    origin = create_public_routine(user: author, name: "O", label: "Old")
    copy = adopt!(adopter: adopter, origin: origin, name: "Nombre copia")
    ExerciseRoutineAssignment.create!(user: adopter, exercise_routine: copy, start_week: 1, end_week: 3)
    assignment_id = copy.exercise_routine_assignments.sole.id

    origin.exercise_routine_lines.first.update!(label: "New move")

    fp = ExerciseRoutines::ContentFingerprint.for_routine(origin.reload)
    post accept_source_update_exercise_routine_path(copy), params: { expected_origin_fingerprint: fp }

    expect(response).to redirect_to(edit_exercise_routine_path(copy))
    copy.reload
    expect(copy.name).to eq("Nombre copia")
    expect(copy.exercise_routine_lines.sole.label).to eq("New move")
    expect(copy.exercise_routine_assignments.sole.id).to eq(assignment_id)
  end

  # [REQ-EXR-006]
  it "rejects apply when the source changed again after the form was rendered" do
    origin = create_public_routine(user: author, name: "O", label: "V1")
    copy = adopt!(adopter: adopter, origin: origin)
    origin.exercise_routine_lines.first.update!(label: "V2")
    fp_at_render = ExerciseRoutines::ContentFingerprint.for_routine(origin.reload)
    origin.exercise_routine_lines.first.update!(label: "V3")

    post accept_source_update_exercise_routine_path(copy), params: { expected_origin_fingerprint: fp_at_render }

    expect(response).to redirect_to(edit_exercise_routine_path(copy))
    expect(flash[:alert]).to eq(I18n.t("exercise_routines.adoption_sync.errors.origin_changed_retry"))
    copy.reload
    expect(copy.exercise_routine_lines.sole.label).to eq("V1")
  end

  # [REQ-EXR-006]
  it "shows unavailable on edit when the source was deleted" do
    origin = create_public_routine(user: author, name: "Gone", label: "x")
    copy = adopt!(adopter: adopter, origin: origin)
    origin.destroy!

    get edit_exercise_routine_path(copy.reload)

    expect(response.body).to include(I18n.t("exercise_routines.edit.adoption_sync.unavailable"))
  end

  # [REQ-EXR-006]
  it "shows unavailable when the source is no longer public" do
    origin = create_public_routine(user: author, name: "Priv", label: "y")
    copy = adopt!(adopter: adopter, origin: origin)
    origin.update!(publicly_shareable: false)

    get edit_exercise_routine_path(copy.reload)

    expect(response.body).to include(I18n.t("exercise_routines.edit.adoption_sync.unavailable"))
  end

  # [REQ-EXR-006]
  it "returns 404 for public show of a deleted routine" do
    sign_in!(adopter)
    origin = create_public_routine(user: author, name: "Del", label: "z")
    rid = origin.id
    origin.destroy!

    expect { get public_exercise_routine_path(rid) }.not_to raise_exception
    expect(response).to have_http_status(:not_found)
  end
end
