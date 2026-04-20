# frozen_string_literal: true

require "rails_helper"

RSpec.describe Programs::AdoptionSyncStatus do
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def routine_with_line(user, name)
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "L")
    r.save!
    r
  end

  # [REQ-PHS-001]
  it "returns none when the program is not an adopted copy" do
    program = PhaseProgram.create!(user: adopter, name: "Local", publicly_shareable: false)

    expect(described_class.for_program(program).key).to eq(:none)
  end

  # [REQ-PHS-001]
  it "returns unavailable when the source is no longer public" do
    menu = Menu.create!(user: author, name: "M")
    routine = routine_with_line(author, "R")
    source = PhaseProgram.create!(user: author, name: "Src", publicly_shareable: true)
    PhaseProgramAssignment.create!(phase_program: source, menu: menu, exercise_routine: routine, start_week: 1, end_week: 2)
    copy = Programs::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "Copia")

    source.update!(publicly_shareable: false)

    expect(described_class.for_program(copy.reload).key).to eq(:unavailable)
  end

  # [REQ-PHS-001]
  it "returns pending when the source template fingerprint drifts" do
    menu = Menu.create!(user: author, name: "M")
    MenuEntry.create!(menu: menu, weekday: 0, meal_type: "cena", freeform_text: "A")
    routine = routine_with_line(author, "R")
    source = PhaseProgram.create!(user: author, name: "Src", publicly_shareable: true)
    PhaseProgramAssignment.create!(phase_program: source, menu: menu, exercise_routine: routine, start_week: 1, end_week: 2)
    copy = Programs::AdoptFromPublicCatalog.call(adopter: adopter, source: source, chosen_name: "Copia")

    menu.menu_entries.sole.update!(freeform_text: "B")

    st = described_class.for_program(copy.reload)
    expect(st.key).to eq(:pending)
    expect(st.origin_fingerprint).to eq(Programs::ContentFingerprint.for_program(source.reload))
  end
end
