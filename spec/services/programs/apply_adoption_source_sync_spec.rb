# frozen_string_literal: true

require "rails_helper"

RSpec.describe Programs::ApplyAdoptionSourceSync do
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def routine_with_line(user, name)
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "L")
    r.save!
    r
  end

  # [REQ-PHS-001]
  it "raises not_adopted_copy when there is no adoption metadata" do
    program = PhaseProgram.create!(user: adopter, name: "X", publicly_shareable: false)

    expect do
      described_class.call(copy: program)
    end.to raise_error(described_class::Error) { |e| expect(e.key).to eq(:not_adopted_copy) }
  end

  # [REQ-PHS-001]
  it "rebuilds segments and bumps fingerprint when the source template changed" do
    menu = Menu.create!(user: author, name: "M")
    MenuEntry.create!(menu: menu, weekday: 0, meal_type: "cena", freeform_text: "Old")
    routine = routine_with_line(author, "R")
    source = PhaseProgram.create!(user: author, name: "Src", publicly_shareable: true)
    PhaseProgramAssignment.create!(phase_program: source, menu: menu, exercise_routine: routine, start_week: 1, end_week: 2)
    copy = Programs::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "Copia")

    old_menu_id = copy.phase_program_assignments.sole.menu_id
    menu.menu_entries.sole.update!(freeform_text: "New")

    described_class.call(copy: copy.reload)

    copy.reload
    expect(copy.source_sync_fingerprint).to eq(Programs::ContentFingerprint.for_program(source.reload))
    new_menu_id = copy.phase_program_assignments.sole.menu_id
    expect(new_menu_id).not_to eq(old_menu_id)
    expect(Menu.find(new_menu_id).menu_entries.sole.freeform_text).to include("New")
  end
end
