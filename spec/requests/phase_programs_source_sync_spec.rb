# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phase program adoption source sync", type: :request do
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def routine_with_line(user, name)
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "L")
    r.save!
    r
  end

  # [REQ-PHS-001]
  it "applies source update from the edit screen" do
    menu = Menu.create!(user: author, name: "M")
    MenuEntry.create!(menu: menu, weekday: 1, meal_type: "almuerzo", freeform_text: "v1")
    routine = routine_with_line(author, "R")
    source = PhaseProgram.create!(user: author, name: "Plantilla", publicly_shareable: true)
    PhaseProgramAssignment.create!(phase_program: source, menu: menu, exercise_routine: routine, start_week: 1, end_week: 3)

    post sign_in_path, params: { email: adopter.email, password: "Password123!" }
    post adopt_public_phase_program_path(source), params: { name: "Mi pack" }
    copy = PhaseProgram.find_by!(user: adopter, name: "Mi pack")

    menu.menu_entries.sole.update!(freeform_text: "v2")
    fp = Programs::ContentFingerprint.for_program(source.reload)

    post accept_source_update_phase_program_path(copy), params: { expected_origin_fingerprint: fp }

    expect(response).to redirect_to(edit_phase_program_path(copy))
    expect(flash[:notice]).to eq(I18n.t("phase_programs.flash.source_sync_applied"))
    expect(Menu.find(copy.reload.phase_program_assignments.sole.menu_id).menu_entries.sole.freeform_text).to include("v2")
  end
end
