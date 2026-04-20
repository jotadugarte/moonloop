# frozen_string_literal: true

require "rails_helper"

RSpec.describe Programs::AdoptFromPublicCatalog do
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  def routine_with_line(user, name)
    r = ExerciseRoutine.new(user: user, name: name)
    r.exercise_routine_lines.build(weekday: 0, position: 0, label: "Move")
    r.save!
    r
  end

  # [REQ-PHS-001]
  it "creates an adopted program with duplicated menus, routines, and segments" do
    menu = Menu.create!(user: author, name: "M author")
    MenuEntry.create!(menu: menu, weekday: 1, meal_type: "cena", freeform_text: "Soup")
    routine = routine_with_line(author, "R author")
    source = PhaseProgram.create!(user: author, name: "Template", publicly_shareable: true)
    PhaseProgramAssignment.create!(
      phase_program: source,
      menu: menu,
      exercise_routine: routine,
      start_week: 1,
      end_week: 4
    )

    copy = described_class.call(adopter: adopter, source: source, chosen_name: "  Mi programa  ")

    expect(copy.user_id).to eq(adopter.id)
    expect(copy.name).to eq("Mi programa")
    expect(copy.source_phase_program_id).to eq(source.id)
    expect(copy.adoption_catalog_origin_id).to eq(source.id)
    expect(copy.source_sync_fingerprint).to eq(Programs::ContentFingerprint.for_program(source))
    expect(copy.publicly_shareable).to eq(false)

    seg = copy.phase_program_assignments.sole
    expect(seg.start_week).to eq(1)
    expect(seg.end_week).to eq(4)
    expect(seg.menu.user_id).to eq(adopter.id)
    expect(seg.menu.menu_entries.sole.freeform_text).to include("Soup")
    expect(seg.exercise_routine.user_id).to eq(adopter.id)
    expect(seg.exercise_routine.exercise_routine_lines.sole.label).to eq("Move")
  end

  # [REQ-PHS-001]
  it "reuses one menu copy when two segments share the same menu" do
    menu = Menu.create!(user: author, name: "Shared M")
    r1 = routine_with_line(author, "R1")
    r2 = routine_with_line(author, "R2")
    source = PhaseProgram.create!(user: author, name: "Dup menu", publicly_shareable: true)
    PhaseProgramAssignment.create!(phase_program: source, menu: menu, exercise_routine: r1, start_week: 1, end_week: 2)
    PhaseProgramAssignment.create!(phase_program: source, menu: menu, exercise_routine: r2, start_week: 3, end_week: 4)

    copy = described_class.call(adopter: adopter, source: source, chosen_name: "Pack")

    expect(adopter.menus.where("name LIKE ?", "Pack — Shared M%").count).to eq(1)
    expect(copy.phase_program_assignments.pluck(:menu_id).uniq.size).to eq(1)
    expect(copy.phase_program_assignments.count).to eq(2)
  end

  # [REQ-PHS-001]
  it "raises already_adopted on a second adoption of the same source" do
    menu = Menu.create!(user: author, name: "M")
    routine = routine_with_line(author, "R")
    source = PhaseProgram.create!(user: author, name: "Once", publicly_shareable: true)
    PhaseProgramAssignment.create!(phase_program: source, menu: menu, exercise_routine: routine, start_week: 1, end_week: 2)

    described_class.call(adopter: adopter, source: source, chosen_name: "Primera")

    expect do
      described_class.call(adopter: adopter, source: source, chosen_name: "Segunda")
    end.to raise_error(described_class::Error) { |e| expect(e.key).to eq(:already_adopted) }
  end

  # [REQ-PHS-001]
  it "raises not_public when the source is not shareable" do
    source = PhaseProgram.create!(user: author, name: "Privado", publicly_shareable: false)

    expect do
      described_class.call(adopter: adopter, source: source, chosen_name: "X")
    end.to raise_error(described_class::Error) { |e| expect(e.key).to eq(:not_public) }
  end

  # [REQ-PHS-001]
  it "raises cannot_adopt_own when adopter owns the source program" do
    source = PhaseProgram.create!(user: adopter, name: "Mine", publicly_shareable: true)

    expect do
      described_class.call(adopter: adopter, source: source, chosen_name: "Nope")
    end.to raise_error(described_class::Error) { |e| expect(e.key).to eq(:cannot_adopt_own) }
  end
end
