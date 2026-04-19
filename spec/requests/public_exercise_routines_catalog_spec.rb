# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public exercise routines catalog", type: :request do
  let(:viewer) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: viewer.email, password: "Password123!" }
  end

  def create_routine(user:, name:, publicly_shareable:)
    r = ExerciseRoutine.new(user: user, name: name, publicly_shareable: publicly_shareable)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Warmup")
    r.save!
    r
  end

  # [REQ-EXR-006] — public browse catalog (index/show); REQ-ID finalized in SPEC step 9 of task plan
  it "lists only routines that are publicly shareable" do
    create_routine(user: author, name: "Pública", publicly_shareable: true)
    create_routine(user: author, name: "Privada", publicly_shareable: false)

    get public_exercise_routines_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Pública")
    expect(response.body).not_to include("Privada")
  end

  it "shows a publicly shareable routine by id" do
    routine = create_routine(user: author, name: "Full body", publicly_shareable: true)

    get public_exercise_routine_path(routine)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Full body")
  end

  it "returns not found for a routine that is not publicly shareable" do
    routine = create_routine(user: author, name: "Secret", publicly_shareable: false)

    get public_exercise_routine_path(routine)

    expect(response).to have_http_status(:not_found)
  end

  it "returns not found after public sharing is revoked" do
    routine = create_routine(user: author, name: "Was public", publicly_shareable: true)
    routine.update!(publicly_shareable: false)

    get public_exercise_routine_path(routine)

    expect(response).to have_http_status(:not_found)
  end

  it "does not expose author email in index or show HTML" do
    routine = create_routine(user: author, name: "Shared plan", publicly_shareable: true)
    expect(author.email).to be_present

    get public_exercise_routines_path
    expect(response.body).not_to include(author.email)

    get public_exercise_routine_path(routine)
    expect(response.body).not_to include(author.email)
  end
end
