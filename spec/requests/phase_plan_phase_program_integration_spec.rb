# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phase plan + phase programs integration", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def routine_with_line(name)
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Move")
    r.save!
    r
  end

  # [REQ-PHS-001]
  it "shows active menu and routine from Phases::WeekNumber after applying a program bundle" do
    user.update!(phase_one_starts_on: Date.new(2026, 4, 10))
    menu = Menu.create!(user: user, name: "Menú coordinado")
    routine = routine_with_line("Rutina coordinada")
    program = PhaseProgram.create!(user: user, name: "Pack", publicly_shareable: false)
    PhaseProgramAssignment.create!(
      phase_program: program,
      menu: menu,
      exercise_routine: routine,
      start_week: 1,
      end_week: 20
    )

    post sign_in_path, params: { email: user.email, password: "Password123!" }

    travel_to(Time.zone.parse("2026-04-12 12:00:00")) do
      post apply_phase_program_path(program)
      expect(response).to have_http_status(:found)

      get phase_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("phases.show.current_week", index: 1))
      expect(response.body).to include("Menú coordinado")
      expect(response.body).to include("Rutina coordinada")
    end
  end

  # [REQ-PHS-001]
  it "surfaces the programs intro and link on the phase dashboard" do
    post sign_in_path, params: { email: user.email, password: "Password123!" }

    get phase_path

    expect(response.body).to include(I18n.t("phases.show.programs_intro_heading"))
    expect(response.body).to include(phase_programs_path)
  end
end
