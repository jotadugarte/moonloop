# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public phase programs catalog", type: :request do
  let(:viewer) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: viewer.email, password: "Password123!" }
  end

  def routine_for(u, name)
    r = ExerciseRoutine.new(user: u, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Line")
    r.save!
    r
  end

  # [REQ-PHS-001]
  it "lists only programs that are publicly shareable" do
    PhaseProgram.create!(user: author, name: "Público", publicly_shareable: true)
    PhaseProgram.create!(user: author, name: "Privado", publicly_shareable: false)

    get public_phase_programs_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Público")
    expect(response.body).not_to include("Privado")
  end

  # [REQ-PHS-001]
  it "shows a public program and its segment lines" do
    menu = Menu.create!(user: author, name: "M")
    routine = routine_for(author, "R")
    program = PhaseProgram.create!(user: author, name: "Plan fit", publicly_shareable: true)
    PhaseProgramAssignment.create!(
      phase_program: program,
      menu: menu,
      exercise_routine: routine,
      start_week: 1,
      end_week: 4
    )

    get public_phase_program_path(program)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Plan fit")
    expect(response.body).to include("M")
    expect(response.body).to include("R")
  end

  # [REQ-PHS-001]
  it "returns not found for a program that is not publicly shareable" do
    program = PhaseProgram.create!(user: author, name: "Secret", publicly_shareable: false)

    get public_phase_program_path(program)

    expect(response).to have_http_status(:not_found)
  end

  # [REQ-PHS-001]
  it "does not expose author email in index or show HTML" do
    program = PhaseProgram.create!(user: author, name: "Shared program", publicly_shareable: true)
    expect(author.email).to be_present

    get public_phase_programs_path
    expect(response.body).not_to include(author.email)

    get public_phase_program_path(program)
    expect(response.body).not_to include(author.email)
  end
end
