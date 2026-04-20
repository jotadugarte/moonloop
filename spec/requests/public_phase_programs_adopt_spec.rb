# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public phase programs adopt", type: :request do
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def routine_with_line(user, name)
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "x")
    r.save!
    r
  end

  # [REQ-PHS-001]
  context "when signed in as adopter" do
    before do
      post sign_in_path, params: { email: adopter.email, password: "Password123!" }
    end

    it "creates an adopted copy with chosen name, segments, and source link" do
      menu = Menu.create!(user: author, name: "Menú origen")
      routine = routine_with_line(author, "Rutina origen")
      origin = PhaseProgram.create!(user: author, name: "Plan autor", publicly_shareable: true)
      PhaseProgramAssignment.create!(
        phase_program: origin,
        menu: menu,
        exercise_routine: routine,
        start_week: 2,
        end_week: 5
      )

      expect do
        post adopt_public_phase_program_path(origin), params: { name: "Mi copia programa" }
      end.to change { PhaseProgram.count }.by(1)

      expect(response).to have_http_status(:found)
      copy = PhaseProgram.find_by!(user: adopter, name: "Mi copia programa")
      expect(copy.source_phase_program_id).to eq(origin.id)
      expect(copy.phase_program_assignments.sole.start_week).to eq(2)
      expect(response.headers["Location"]).to include(edit_phase_program_path(copy))
    end

    it "rejects a second adoption of the same origin" do
      menu = Menu.create!(user: author, name: "M")
      routine = routine_with_line(author, "R")
      origin = PhaseProgram.create!(user: author, name: "Once", publicly_shareable: true)
      PhaseProgramAssignment.create!(phase_program: origin, menu: menu, exercise_routine: routine, start_week: 1, end_week: 2)

      post adopt_public_phase_program_path(origin), params: { name: "Primera" }
      expect(response).to have_http_status(:found)

      post adopt_public_phase_program_path(origin), params: { name: "Segunda" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("public_phase_programs.adopt.errors.already_adopted"))
    end

    it "rejects adoption of the adopter's own public program" do
      menu = Menu.create!(user: adopter, name: "M own")
      routine = routine_with_line(adopter, "R own")
      own = PhaseProgram.create!(user: adopter, name: "Mine", publicly_shareable: true)
      PhaseProgramAssignment.create!(phase_program: own, menu: menu, exercise_routine: routine, start_week: 1, end_week: 2)

      post adopt_public_phase_program_path(own), params: { name: "Try" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("public_phase_programs.adopt.errors.cannot_adopt_own"))
    end

    it "rejects adoption when the chosen program name collides for the adopter" do
      PhaseProgram.create!(user: adopter, name: "Existing", publicly_shareable: false)
      menu = Menu.create!(user: author, name: "M")
      routine = routine_with_line(author, "R")
      origin = PhaseProgram.create!(user: author, name: "Origin", publicly_shareable: true)
      PhaseProgramAssignment.create!(phase_program: origin, menu: menu, exercise_routine: routine, start_week: 1, end_week: 2)

      post adopt_public_phase_program_path(origin), params: { name: "Existing" }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq(I18n.t("adoption.invalid_record.name_taken"))
    end
  end

  # [REQ-PHS-001]
  context "when not signed in" do
    it "redirects to sign in" do
      menu = Menu.create!(user: author, name: "M")
      routine = routine_with_line(author, "R")
      origin = PhaseProgram.create!(user: author, name: "Publico", publicly_shareable: true)
      PhaseProgramAssignment.create!(phase_program: origin, menu: menu, exercise_routine: routine, start_week: 1, end_week: 2)

      post adopt_public_phase_program_path(origin), params: { name: "Nope" }

      expect(response).to redirect_to(sign_in_path)
    end
  end
end
